import os
import os.path as op
import sys

from mriqc.workflows.anatomical import anat_qc_workflow
from mriqc.testing import mock_config

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

for file in os.listdir(os.path.join(dataDir, subId, 'anat')):
    if file.endswith(".nii.gz"):
        fileToCheck = os.path.join(dataDir, subId, 'anat', file)
        print(fileToCheck)

        with mock_config():
            print(fileToCheck)
            wf = anat_qc_workflow([fileToCheck], modDir, templateDir)
            wf.run()
