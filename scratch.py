import mne
import numpy as np
import matplotlib.pyplot as plt
# from visbrain import Sleep

f = "/home/roger/Documents/jacob/pieces/eoiayidbyII/data/n11/n11.edf"
annotation = "home/roger/Documents/jacob/pieces/eoiayidbyII/data/n11/n11.txt"
exclude = ["ROC-LOC", "ECG1-ECG2", "DX1-DX2", "SX1-SX2", "SAO2", "PLETH", "STAT"] # don't use these channels
bands = [(5,20), (21,45), (46,80), (81,125), (126,155), (156,200)]
output = open("/home/roger/Documents/jacob/pieces/eoiayidbyII/data/n11/n11_analysis", "w")

def normalize_complex_arr(a):
  a_oo = a - a.real.min() - 1j*a.imag.min() # origin offsetted
  return a_oo/np.abs(a_oo).max() # divide by the max magnitude

raw = mne.io.read_raw_edf(f, exclude=exclude)
# raw.plot(block=True, lowpass=40)

overlap = 0.5
seg_length = int(raw.info['sfreq'] * 2)
advance = seg_length * overlap
num_segs = int(raw.n_times/advance) # number of samples to advance per loop
print (num_segs)

time = (512 + advance) / raw.info['sfreq']

# get the raw values into their own arary
data = raw.get_data([0], 0, 0+seg_length)
pad = (5120-len(data[0]))
hr = raw.get_data([14], 0, 0+seg_length)[0]
hr = sum(hr)/len(hr)
data = np.lib.pad(data, pad_width=(0,pad), mode='constant', constant_values=0)
data = mne.filter.filter_data(data, raw.info['sfreq'], l_freq=None, h_freq=50, fir_design='firwin')

fft = np.fft.fft(data)
fft = normalize_complex_arr(fft)
x_axis = np.fft.fftfreq(5120, 1/raw.info['sfreq'])
x_axis = x_axis[0:749]
fft = fft[0][0:749].real
# print (x_axis)

# get the bands
delta = sum(fft[bands[0][0]:bands[0][1]])
theta = sum(fft[bands[1][0]:bands[1][1]])
alpha = sum(fft[bands[2][0]:bands[2][1]])
beta = sum(fft[bands[3][0]:bands[3][1]])
gamma = sum(fft[bands[4][0]:bands[4][1]])

spectralSum = sum([delta, theta, alpha, beta, gamma])
delta = delta/spectralSum
theta = theta/spectralSum
alpha = alpha/spectralSum
beta = beta/spectralSum
gamma = gamma/spectralSum

line = ', '.join(map(str, (time, delta, theta, alpha, beta, gamma, hr)))
line += "\n"
output.write(line)

output.close()

# plt.plot(fft)
# plt.show()
