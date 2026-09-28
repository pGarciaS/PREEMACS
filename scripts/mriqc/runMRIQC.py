import os
import os.path as op
import sys
from pathlib import Path

from mriqc.workflows.anatomical import anat_qc_workflow
from mriqc.testing import mock_config
from mriqc import config as mriqc_config

# dataDir = '/home/kilimanjaro2/Research/monkeyStuff/bidsData/'
# templatedir = '/home/kilimanjaro2/Research/monkeyStuff/templates/'
# moddir = '/home/kilimanjaro2/Research/monkeyStuff/secondN4/'

# print('Argument List:', str(sys.argv))

#bids data location
dataDir = str(sys.argv[1])
print(dataDir)

#template location
templateDir = str(sys.argv[2])
print(templateDir)

#n4 corrected directory
modDir = str(sys.argv[3])
print(modDir)

subId = str(sys.argv[4])
print(subId)

t1_conform = os.path.join(dataDir, subId, 'T1_conform.nii.gz')

# anat_qc_workflow's _get_mod/_get_imgtype helpers parse the modality off the
# filename's last "_"-separated, BIDS-suffix token (e.g. "..._T1w.nii.gz"),
# not off M1's own "T1_conform.nii.gz" naming (modality-first). Stage a
# BIDS-style-named symlink next to the real file -- same directory, so the
# workflow's own subject-ID derivation (one level up from the file) still
# resolves to subId -- rather than touch M1's actual output filename or the
# vendored helper functions.
fileToCheck = os.path.join(dataDir, subId, f'{subId}_T1w.nii.gz')
if os.path.islink(fileToCheck) or os.path.exists(fileToCheck):
    os.remove(fileToCheck)
os.symlink(t1_conform, fileToCheck)
print(fileToCheck)

with mock_config():
    # Both of these must be set BEFORE anat_qc_workflow() is called below --
    # compute_iqms() (called from inside anat_qc_workflow) reads
    # config.execution.output_dir at workflow-*construction* time and bakes
    # it into the `datasink` (IQMFileSink) node's `out_dir` input right
    # then; setting it afterward has no effect on that already-built node.
    mriqc_work_dir = os.path.join(dataDir, subId, 'MRIQC')
    os.makedirs(mriqc_work_dir, exist_ok=True)
    # mock_config() loads data/config-example.toml, whose execution.output_dir
    # is the relative path "derivatives/" -- resolved against os.getcwd(),
    # which is /opt/preemacs/Modules inside the container's read-only image
    # (runMRIQC.sh's %apprun cd's there before invoking this script). Point
    # it at a writable, absolute path instead.
    mriqc_config.execution.output_dir = Path(os.path.join(mriqc_work_dir, 'derivatives'))
    mriqc_config.execution.output_dir.mkdir(parents=True, exist_ok=True)
    # Vendored default is no_sub=False, which makes anat_qc_workflow() add an
    # UploadMetrics node that POSTs the IQMs (plus the input file's md5 and
    # software/version info) to mriqc.nimh.nih.gov. Never wanted from this
    # pipeline; like output_dir, it is read at workflow-construction time.
    mriqc_config.execution.no_sub = True

    wf = anat_qc_workflow([fileToCheck], modDir, templateDir)
    # Same read-only-cwd problem for nipype's own wf.base_dir (unset
    # defaults to os.getcwd() too) -- this one only affects wf.run()
    # itself, not node construction, so setting it after building the
    # workflow (but still before running it) is fine.
    wf.base_dir = mriqc_work_dir
    wf.run()
