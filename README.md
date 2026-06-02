# Computer-Vision-Pipeline-for-Door-Detection

## Overview

This project implements a complete computer vision pipeline in MATLAB for automatic door detection and corner localization from a single image. The system processes an input image, extracts relevant features, identifies door boundaries, and determines the four corner coordinates of the detected door frame.

The project was developed as part of a computer vision and image processing laboratory exercise and demonstrates the use of classical image processing techniques without relying on machine learning models.

---

## Features

* Image preprocessing and contrast enhancement
* Noise reduction using a binomial filter
* Gradient-based edge detection using Scharr operators
* Edge classification and thresholding
* Morphological filtering and candidate extraction
* Hough Transform based line detection
* Automatic identification of door frame boundaries
* Corner localization through geometric line intersection
* Visualization of intermediate processing stages

---

## Processing Pipeline

### 1. Image Preprocessing

The input RGB image is converted to grayscale and enhanced using contrast stretching. Noise is reduced using a separable 5×5 binomial filter.

**Techniques used:**

* Grayscale conversion
* Histogram stretching (`imadjust`)
* Binomial smoothing filter

---

### 2. Edge Detection

Image gradients are computed using Scharr operators in both horizontal and vertical directions.

**Outputs:**

* Horizontal gradient image
* Vertical gradient image
* Edge magnitude image

Strong edges are separated from noise using an adaptive threshold based on the average gradient magnitude.

---

### 3. Candidate Extraction

Morphological operations are applied to isolate structures that may correspond to door boundaries.

**Operations used:**

* Noise removal (`bwareaopen`)
* Dilation
* Morphological closing
* Symmetry analysis

This stage produces candidate vertical and horizontal door frame regions.

---

### 4. Line Detection

The Hough Transform is used to detect dominant straight lines corresponding to the door frame.

Detected lines are filtered to identify:

* Left door boundary
* Right door boundary
* Upper frame boundary
* Lower frame boundary

---

### 5. Corner Localization

The four door corners are computed by calculating the intersections of the detected boundary lines.

Corners identified:

* Left Upper (LU)
* Right Upper (RU)
* Left Bottom (LB)
* Right Bottom (RB)

The final coordinates are displayed and visualized on the original image.

---

## Technologies Used

* MATLAB
* Image Processing Toolbox

---

## Concepts Demonstrated

* Image enhancement
* Convolution filtering
* Gradient computation
* Edge detection
* Mathematical morphology
* Hough Transform
* Geometric modelling
* Line intersection analysis
* Feature extraction

---

## Results

The pipeline successfully identifies door frame boundaries and computes the four corner coordinates from a single image. The approach demonstrates how classical computer vision techniques can be combined to solve a real-world object localization problem without the use of machine learning or deep learning methods.

---

## Author

Akshat Pathak

Bachelor's in Robotics Engineering
Technische Hochschule Würzburg-Schweinfurt (THWS)
