import mne
import scipy.io.wavfile as wav
import matplotlib.pyplot as plt
import numpy as np
from sklearn.preprocessing import normalize

f = "/home/roger/Documents/jacob/pieces/eoiayidbyII/data/n11/n11.edf"
raw = mne.io.read_raw_edf(f)
# the filter
# coeff = sig.firwin(numtaps=10000, cutoff=10, nyq=raw.info['sfreq']/2)

cardio = raw.get_data(15, 0, None, True)[0]
cardio = np.array(cardio)
cardio = cardio / np.linalg.norm(cardio)
# cardio = sig.lfilter(coeff, 1.0, cardio)

wav.write("/home/roger/Documents/jacob/pieces/eoiayidbyII/data/n11/n11.wav", int(raw.info['sfreq']), cardio)

# plt.plot(cardio)
# plt.show()
