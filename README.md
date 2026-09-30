# **PREEMACS**  
pipeline for **PRE**processing and **E**xtraction of the **MAC**aque brain **S**urface

**PREEMACS** is a set of tools taken from several image processing softwares commonly used for human data analysis, customized for Rhesus monkeys brain surface extraction and cortical thickness analysis.

![Alt text](https://github.com/pGarciaS/PREEMACS/blob/master/examples/PREEMACS_NHP_FREESURFER.png?raw=true)

# **Install**

:star: **NEW IN SEPT 30, 2026!!** :star:

The easiest way to run PREEMACS is the **Singularity/Apptainer container** described below. It is fantastic, as it bundles every dependency (FSL, FreeSurfer, ANTs, MRtrix3, AFNI, MINC, Octave, and PREEMACS' own Python environments). This way nothing needs to be installed by hand! For a from-source install, review the Wiki.

## **Singularity / Apptainer Container**

`preemacs.def` builds a single container image with the whole pipeline and its full toolchain pinned to known-working versions:

| Tool | Version |
|---|---|
| FSL | 6.0.4 |
| FreeSurfer | 7.4.1 |
| ANTs | 2.4.4 |
| MRtrix3 | 3.0.4 |
| AFNI | latest `linux_openmp_64` build (only `afni`/`3dFWHMx`, used by the QC module) |
| MINC toolkit | 1.9.18 (`mincnlm` only) |
| Octave | 6.4.0 (stands in for MATLAB — PREEMACS' `.m` scripts don't use any MATLAB-only toolbox) |

### Building the image

Requires [Apptainer](https://apptainer.org/) (or Singularity) with `--fakeroot` support:

```bash
git clone https://github.com/lconcha/PREEMACS.git && cd PREEMACS
apptainer build --fakeroot preemacs.sif preemacs.def
```

:warning: The build downloads several large files (FreeSurfer ~9GB, FSL ~4GB, AFNI ~1GB) and takes roughly 35–40 minutes on a typical connection. If you're rebuilding repeatedly, put pre-downloaded copies of those files in `container/cache/` (see `preemacs.def`'s `%setup` section for the exact filenames). 💾 The resulting `preemacs.sif` container is around 18 GB!

### Before running anything

FreeSurfer requires a free license file, and it cannot be bundled into the image (no redistribution rights). Get one from https://surfer.nmr.mgh.harvard.edu/registration.html and bind it in on every run that touches FreeSurfer (M1, BM, M3):

```
--bind /path/to/your/license.txt:/opt/freesurfer/license.txt --env FS_LICENSE=/opt/freesurfer/license.txt
```

The `--env` is not optional if `$FS_LICENSE` is already set in your own shell (common, since it's FreeSurfer's own recommended variable name for this) — Apptainer passes host environment variables into the container by default, and FreeSurfer prioritizes `$FS_LICENSE` over the file at `/opt/freesurfer/license.txt`. Without the `--env` override, a pre-existing host `$FS_LICENSE` silently wins and points FreeSurfer at a host-only path it can't see inside the container, failing with a "license file not found" error that has nothing to do with the `--bind` above actually being correct.

### Running the pipeline

PREEMACS is five separate modules, run in this order against the same subject, each producing inputs the next one needs:

```
M1  →  BM  →  generateN4  →  MRIQC  →  M3
```

Each module is a container "app," invoked as `apptainer run --app <APP> preemacs.sif <args>`. All paths below are inside the container — bind your real host directories to `/data/...` as shown.

#### tl;dr :rocket:

`run_full_pipeline.sh` (repo root) runs all five modules in order for you, on the host. This would be similar to a `-recon-all` directive in _freesurfer_'s `recon-all`. 

```bash
./run_full_pipeline.sh SUB_ID T1_PATH T2_PATH OUTPUT_DIR [FS_LICENSE]
```

```bash
./run_full_pipeline.sh sub-01 \
  /data/raw/sub-01_T1w.nii.gz /data/raw/sub-01_T2w.nii.gz \
  /data/results/sub-01 ~/licenses/freesurfer_license.txt
```

`T1_PATH`/`T2_PATH` can be a single file or a directory — including a BIDS `anat/` folder mixing both modalities, which it auto-separates by filename (`*T1w*`/`*T2w*`). Point both at a subject's top-level BIDS folder and add `--all-sessions` to average every run across every session; omit it to only use the one directory you pointed at. Takes 2–3 hours end to end, dominated by `M3`. Run `./run_full_pipeline.sh -h` for the full usage notes and more examples.

:information_source: The rest of this section covers running each module individually, if you want more control over a single step.

**1. `M1` — orientation, cropping, bias correction, averaging, skull-stripping**

`-t1_path`/`-t2_path` are *directories*: every `.nii.gz` file inside is treated as a separate run of that modality and averaged together (put a single file in each if you only have one run per modality).

```bash
apptainer run --app M1 preemacs.sif \
  --bind /path/to/license.txt:/opt/freesurfer/license.txt --env FS_LICENSE=/opt/freesurfer/license.txt \
  --bind /path/to/t1_runs:/data/in_t1 \
  --bind /path/to/t2_runs:/data/in_t2 \
  --bind /path/to/outputs:/data/out \
  -id SUB01 -t1_path /data/in_t1 -t2_path /data/in_t2 -out_path /data/out
```

**2. `BM` — brain extraction (PREEMASK CNN + FSL masking)**

```bash
apptainer run --app BM preemacs.sif \
  --bind /path/to/license.txt:/opt/freesurfer/license.txt --env FS_LICENSE=/opt/freesurfer/license.txt \
  --bind /path/to/outputs:/data/out \
  SUB01 /data/out
```

**3. `generateN4` — a second, independent N4 bias-field correction pass**

Runs on M1's conformed T1 (not the raw scan) so it shares a voxel grid with BM's brain mask.

```bash
apptainer run --app generateN4 preemacs.sif \
  --bind /path/to/outputs:/data/out \
  -dataDir /data/out -maskDir /data/out -id SUB01 -outDir /data/out/N4
```

**4. `MRIQC` — quality-control metrics and report (adapted from MRIQC)**

Evaluates M1's conformed T1 against the bundled macaque (NMT) templates. Produces an HTML report and a JSON file of IQMs under `out_path/SUB01/MRIQC/derivatives/`.

```bash
apptainer run --app MRIQC preemacs.sif \
  --bind /path/to/outputs:/data/out \
  -dataDir /data/out -templateDir /opt/preemacs/templates -n4dir /data/out/N4 -id SUB01
```

If you use MRIQC's output, cite the macaque template it registers against: Seidlitz et al., *"A population MRI brain template and analysis tools for the macaque"*, NeuroImage (2017), doi:10.1101/105874.

**5. `M3` — white matter and pial surface reconstruction (FreeSurfer, macaque-adapted)**

This is the slowest module (typically 1.5–2 hours). It needs its **own** writable directory for FreeSurfer's subject tree — this must be a *different* folder from `-out_path`, because `recon-all` refuses to run on a subject folder that already exists, and `out_path/SUB01` always does by this point.

```bash
apptainer run --app M3 preemacs.sif \
  --bind /path/to/license.txt:/opt/freesurfer/license.txt --env FS_LICENSE=/opt/freesurfer/license.txt \
  --bind /path/to/outputs:/data/out \
  --bind /path/to/freesurfer_subjects:/data/fs \
  --env SUBJECTS_DIR=/data/fs \
  SUB01 /data/out
```

Outputs land in the usual FreeSurfer subject-directory layout under `/data/fs/SUB01/` — surfaces in `surf/` (`lh./rh.white`, `.pial`, `.thickness`, ...), cortical parcellation in `label/` (`lh./rh.aparc.annot`), and volumes in `mri/` (`brain.mgz`, `ribbon.mgz`, `aseg.presurf.mgz`, ...).

### Notes

- `apptainer run --app <APP> preemacs.sif -h` prints each module's own usage/options (e.g. M1's `-mc`/`-mcc` manual-crop flags, `-sphinx`, `-av_FS`).
- `-mc`/`-mcc`/`-qc_LR` on M1 are interactive — they open `fslview` and read from stdin, so they only work under `apptainer shell`, not a headless batch run.
- `apptainer run-help preemacs.sif` prints this same quick-reference from inside the container.

## **Module 1** 

Performs volume orientation, image cropping, intensity non-uniformity correction, and volume averaging, ending with skull-stripping **(PREEMASK brainmask tool)** through a convolutional neural network.

![Alt text](https://github.com/pGarciaS/PREEMACS/blob/master/examples/NHP_brainmask.png?raw=true)

## **Module 2** 

Performs a quality control using an adaptation of MRIqc method to extract quality metrics that are then used to determine the likelihood of accurate brain surface estimation. 

## **Module 3** 

This module estimates the white matter and pial surfaces from the T1-weighted volume (T1w) using an NHP customized version of FreeSurfer.

![Alt text](https://github.com/pGarciaS/PREEMACS/blob/master/examples/PREEMACS_RESULTS.png?raw=true)

## PREEMACS NHP TEMPLATES

In order to customized FreeSurfer to NHP, based on 33 subjects, 29 from PRIME-DE (Milham et al., 2018) and 4 from UNAM-INB data sets, PREEMACS has developed.

1) **PREEMACS FreeSurfer segmentation atlas**, with cortical and subcortical labels

![Alt text](https://github.com/pGarciaS/PREEMACS/blob/master/examples/NHP_FREESURFER_ATLAS.png?raw=true)

2) **PREEMACS Rhesus parameterization template** that includes the Rhesus curvature and sulcal pattern templates for individual monkey WM surface registration

![Alt text](https://github.com/pGarciaS/PREEMACS/blob/master/examples/NHP_FREESURFER_TEMPLATE.PNG?raw=true)

3) **PREEMACS Rhesus average surface** for final mapping of vertices across all animals

![Alt text](https://github.com/pGarciaS/PREEMACS/blob/master/examples/CT_final_analisis._inferno.jpg?raw=true)

