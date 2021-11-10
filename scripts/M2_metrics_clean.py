#!/usr/bin/env python

import csv
import pandas as pd
import sys
import numpy as np
import os
import argparse
import nibabel as nb
from colorama import Fore, Back, init, Style


def load_arguments():

    parser = argparse.ArgumentParser(description="Clean QC metrics and calculate the Dice index to SVM analysis")
    parser.add_argument("-qc",'--quality_control', help="QC metrics as tsv")
    parser.add_argument("-pm",'--preemacs_mask', help="Brainmask after perform PREEMACS Brain Tool Mask")
    parser.add_argument("-NMT","--NMT_mask", help="Individual mask calculated using NMT template")
    parser.add_argument("-o","--outdir", help="Directory where the script will output the dato to SVM analysis")
    args = parser.parse_args()
    return args

var_del=['bids_name','fber','qi_1','qi_2','size_x','size_y','size_z','spacing_x','spacing_y','spacing_z']

def metrics_svm(qc, outdir, pm, NMT):
    df=pd.read_csv(qc,sep='\t')
    for var in var_del:
        del df[var]

    wk_man = nb.load(os.path.join(NMT))
    man_data = wk_man.get_fdata()

    wk_mod = nb.load(os.path.join(pm))
    mod_data = wk_mod.get_fdata()

    match = np.sum(np.logical_and(man_data, mod_data))

    man_sum = np.sum(man_data)
    mod_sum = np.sum(mod_data)

    dice = (2*match)/(man_sum+mod_sum)

    df.insert(0,'DICE',dice)
    df.columns=range(df.shape[1])
    df.to_csv(outdir + 'clean_qc.csv')

    if dice >= 0.93:
        init()
        print( Fore.RED + 'Warning: ' + Style.RESET_ALL + Fore.GREEN + 'Posible problems in brainmask. DICE = ' + str(dice) + '. This results must be interpreted with caution. It is recommendable to review the result of PREEMACS Brainmask Tool.')

if __name__ == "__main__":
    args = load_arguments()

    if not args.quality_control:
        init()
        print(Fore.RED + "The .tsv file with the metrics must be provided. See -h for instructions.")
        sys.exit(1)
    if not args.preemacs_mask:
        print("Should specify the PREEMACS Mask. See -h for instructions.")
        sys.exit(1)
    if not args.NMT_mask:
        print("Should specify the NMT mask . See -h for instructions.")
        sys.exit(1)
    if not args.outdir:
        print("Should specify output. See -h for instructions.")
        sys.exit(1)

    os.makedirs(args.outdir, exist_ok=True)

metrics_svm(args.quality_control,args.outdir,args.preemacs_mask,args.NMT_mask)
