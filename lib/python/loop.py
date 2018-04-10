import mne
import numpy as np
import time
import matplotlib.pyplot as plt

f = "/home/roger/Documents/jacob/pieces/eoiayidbyII/data/n11/n11.edf"
annotation = "home/roger/Documents/jacob/pieces/eoiayidbyII/data/n11/n11.txt"
exclude = ["ROC-LOC", "ECG1-ECG2", "DX1-DX2", "SX1-SX2", "SAO2", "PLETH", "STAT"] # don't use these channels
bands = [(7,45), (48,78), (80,123), (125,150), (153,248), (250,348), (350,448)]
output = open("/home/roger/Documents/jacob/pieces/eoiayidbyII/data/n11/n11_analysis_TEST", "w")

def normalize_complex_arr(a):
  a_oo = a - a.real.min() - 1j*a.imag.min() # origin offsetted
  return a_oo/np.abs(a_oo).max() # divide by the max magnitude

raw = mne.io.read_raw_edf(f, exclude=exclude, preload=True) # load the data into memory
raw, diff = mne.set_eeg_reference(raw, ref_channels=["C4-A1"], copy=False) # set the reference
raw = raw.notch_filter([50], picks=[0,1,2,3,4,5,6,7,8,9,10,11,12], fir_design="firwin") # notch filter everything at 50Hz
raw = raw.filter(l_freq=1, h_freq=50, picks=[0,1,2,3,4,5,6,7,8,9,10,11,12], fir_design="firwin") # bandpass filter everything between 1 and 50 Hz
# raw.plot(block=True, lowpass=40)

overlap = 0.5
seg_length = int(raw.info['sfreq'] * 2)
advance = seg_length * overlap
num_segs = int(raw.n_times/advance) # number of samples to advance per loop
channel = 0 # what channel are we looking at?

for seg in range(num_segs):
  start = int(seg * advance) # get the staring sample
  end = int(start + seg_length) # get the ending sample
  time = start/raw.info['sfreq'] # get the start time of the current frame

  print ("\nStarting segment {}...\n".format(seg)) # tell us where we are

  # get the raw values into their own arary
  data = raw.get_data([channel], start, end) # extact the data from the channel
  pad = (5120-len(data[0])) # get how much padding we need
  data = np.lib.pad(data, pad_width=(0,pad), mode='constant', constant_values=0) # pad it
  # data = mne.filter.filter_data(data, raw.info['sfreq'], l_freq=None, h_freq=50, fir_design='firwin') # filter

  # get the current heartrate
  hr = raw.get_data([14], start, end)[0] # samples in this segment
  hr = sum(hr)/len(hr) # average them

  fft = np.fft.fft(data) # fft
  fft = normalize_complex_arr(fft) # normalize
  x_axis = np.fft.fftfreq(len(data), 1/raw.info['sfreq']) # compute the x-axis
  x_axis = x_axis[0:749] # get only the freqs we care about
  fft = fft[0][0:749].real # get the magnitude only

  # get the bands
  delta = sum(fft[bands[0][0]:bands[0][1]])
  theta = sum(fft[bands[1][0]:bands[1][1]])
  alpha = sum(fft[bands[2][0]:bands[2][1]])
  sigma = sum(fft[bands[3][0]:bands[3][1]])
  beta = sum(fft[bands[4][0]:bands[4][1]])
  gamma1 = sum(fft[bands[5][0]:bands[5][1]])
  gamma2 = sum(fft[bands[6][0]:bands[6][1]])

  # normalize
  spectralSum = sum([delta, theta, alpha, sigma, beta, gamma1, gamma2])
  delta = delta/spectralSum
  theta = theta/spectralSum
  alpha = alpha/spectralSum
  sigma = sigma/spectralSum
  beta = beta/spectralSum
  gamma1 = gamma1/spectralSum
  gamma2 = gamma2/spectralSum

  # make it a string as CSV and write it in the format:
  # time, delta, theta, alpha, sigma, beta, gamma1, gamma2, heartrate
  line = ', '.join(map(str, (time, delta, theta, alpha, sigma, beta, gamma1, gamma2, hr)))
  line += "\n" # a newline
  output.write(line)

output.close()

# plt.plot(fft)
# plt.show()
