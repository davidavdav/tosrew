# tosrew
Some of my experiments during the Torino SRE Workshop 2015

## Exampes / LOG file for how to use Julia speaker rec tools at the BUT cluster

## Principles

 - _relative_ paths
 - shallow scripting (not scripts got SGE that call scripts to produce scripts for matlab)
 - lower case
 - short paths
 - symbolic links

### For instance

| link    | dest    |
|---------|---------|
| lists   | /mnt/matylda5/iplchot/SRE/BEST2011/lists.110718 |
| sad     | /mnt/matylda4/glembek/BEST2011/tasks/Segmentation_Franta_V4/SubtractedAndNice4Paja/data/lab |
| data    | /homes/eva/q/qleuween/data/sid |

## Feature extraction

Only carry out the featue extraction that we need now.  Use `qsub` parallelization
directly, using Julia to sample filelist depending on SGE array
number.  We could also have done this differently, e.g., using Julia
parallelization.

```sh
cat lists/all.sessions_from_heldout_speakers.other | grep ^FISHE1 | awk '$6=="f"' > list/fiser1-f.list
qsub -q all.q@\@blade -l mem_free=1G,ram_free=1G,matylda4=0.1 -cwd -o log -e log -t 1-100 bin/extract-features list/fiser1-f.list
```
This takes a few minutes on 100 cpus. 

## UBM training

There is no general script with options yet, I just tend to put the
options in the ubm training script itself (not great).  The GMMs
themselves have a history encoded.

```sh
$ time bin/train-ubm list/fiser1-f.list data/fisher1-1024s-f.ubm
```

This case---doubling Ng up to 1024, female fisher1 training, took 126
min on 100 CPUs.
