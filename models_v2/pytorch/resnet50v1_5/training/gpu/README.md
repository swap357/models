# Resnet50 Training

Resnet50 Training BKC.

## Model Information

| **Use Case** | **Framework** | **Model Repo** | **Branch/Commit/Tag** | **Optional Patch** |
|:---:| :---: |:--------------:|:---------------------:|:------------------:|
|  Training    |    Pytorch    |       -        |           -           |         -          |

# Pre-Requisite
* Host has Intel® Data Center GPU MAX or ARC
* Host has installed latest Intel® Data Center GPU Max & Flex Series Drivers https://dgpu-docs.intel.com/driver/installation.html
* Host has installed [Intel® Extension for PyTorch](https://intel.github.io/intel-extension-for-pytorch/xpu/latest/)

# Prepare Dataset
## Dataset: imagenet
ImageNet is recommended, the download link is https://image-net.org/challenges/LSVRC/2012/2012-downloads.php.

## Training
1. `git clone https://github.com/IntelAI/models.git`
2. `cd models_v2/pytorch/resnet50v1_5/training/gpu`
3. Run `setup.sh` this will install all the required dependencies & create virtual environment `venv`.
4. Activate virtual env: `. ./venv/bin/activate`
5. Setup required environment paramaters

| **Parameter**                |                                  **export command**                                  |
|:---------------------------:|:------------------------------------------------------------------------------------:|
| **MULTI_TILE**               | `export MULTI_TILE=False` (True or False)                                            |
| **PLATFORM**                 | `export PLATFORM=PVC` (PVC or ARC)                                                 |
| **DATASET_DIR**              |                               `export DATASET_DIR=`                                  |
| **BATCH_SIZE** (optional)    |                               `export BATCH_SIZE=256`                                |
| **PRECISION**  (optional)    | `export PRECISION=BF16` (BF16 or TF32 or FP32 for PVC and BF16 or FP32 for ARC )    |
|**NUM_ITERATIONS** (optional) |                               `export NUM_ITERATIONS=20`                             |
| **OUTPUT_DIR** (optional)    |                               `export OUTPUT_DIR=$PWD`                               |
6. Run `run_model.sh`

## Output

Single-tile output will typically looks like:

```
Epoch: [0][ 20/196]     Time  0.148 ( 0.379)    Data  0.000 ( 0.218)    Loss 7.3804e+00 (8.0065e+00)    Acc@1   0.00 (  0.12)    Acc@5   0.39 (  0.45)
Training performance: batch size:256, throughput:1716.10 image/sec
```

Multi-tile output will typically looks like:
```
[1] Epoch: [0][  20/2503]       Time  0.173 ( 0.855)    Data  0.001 ( 0.072)    Loss 7.6168e+00 (7.5532e+00)     Acc@1   0.39 (  0.08)   Acc@5   0.39 (  0.43)
[1] Training performance: batch size:256, throughput:1474.26 image/sec
[0] Epoch: [0][  20/2503]       Time  0.172 ( 0.861)    Data  0.001 ( 0.065)    Loss 7.6672e+00 (7.5610e+00)     Acc@1   0.00 (  0.16)   Acc@5   0.00 (  0.74)
[0] Training performance: batch size:256, throughput:1473.24 image/sec
```
Final results of the training run can be found in `results.yaml` file.

```
results:
 - key: throughput
   value: 1716.1
   unit: image/s
 - key: latency
   value: 0.14917545597575899
   unit: s
 - key: accuracy
   value: 7.380
   unit: loss
```
