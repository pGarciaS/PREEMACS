"""Print a voxel seed (x y z) inside the corpus callosum labelled by mri_cc.

usage: cc_seed.py <aseg.mgz containing CC labels 251-255>

Returns the labelled CC voxel closest to the CC centroid (the centroid of a
curved structure can fall outside it), for mri_fill -CV.
"""
import sys

import nibabel as nib
import numpy as np

aseg = np.asarray(nib.load(sys.argv[1]).dataobj)
idx = np.argwhere(np.isin(aseg, [251, 252, 253, 254, 255]))
if len(idx) == 0:
    sys.exit("cc_seed.py: no corpus callosum labels (251-255) in %s -- mri_cc failed" % sys.argv[1])
centroid = idx.mean(0)
print(*[int(v) for v in idx[np.argmin(((idx - centroid) ** 2).sum(1))]])
