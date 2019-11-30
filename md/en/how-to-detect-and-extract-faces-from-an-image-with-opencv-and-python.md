---
author: Akshay Sinha
date: 2019-03-27
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-detect-and-extract-faces-from-an-image-with-opencv-and-python
---

# How To Detect and Extract Faces from an Image with OpenCV and Python

_The author selected the [Open Internet/Free Speech Fund](https://www.brightfunds.org/funds/open-internet-free-speech) to receive a donation as part of the [Write for DOnations](https://do.co/w4do-cta) program._

## Introduction

Images make up a large amount of the data that gets generated each day, which makes the ability to process these images important. One method of processing images is via _face detection_. Face detection is a branch of image processing that uses machine learning to detect faces in images.

A [Haar Cascade](https://docs.opencv.org/3.4.3/d7/d8b/tutorial_py_face_detection.html) is an object detection method used to locate an object of interest in images. The algorithm is trained on a large number of positive and negative samples, where positive samples are images that contain the object of interest. Negative samples are images that may contain anything but the desired object. Once trained, the classifier can then locate the object of interest in any new images.

In this tutorial, you will use a pre-trained [Haar Cascade](https://github.com/opencv/opencv/tree/master/data/haarcascades) model from [OpenCV](https://opencv.org/) and [Python](https://www.python.org/) to detect and extract faces from an image. OpenCV is an open-source programming library that is used to process images.

## Prerequisites

- A [local Python 3 development environment](https://www.digitalocean.com/community/tutorial_series/how-to-install-and-set-up-a-local-programming-environment-for-python-3), including [`pip`](https://pypi.org/project/pip/), a tool for installing Python packages, and [`venv`](https://docs.python.org/3/library/venv.html), for creating virtual environments.

## Step 1 — Configuring the Local Environment

Before you begin writing your code, you will first create a workspace to hold the code and install a few dependencies.

Create a directory for the project with the `mkdir` command:

    mkdir face_scrapper

Change into the newly created directory:

    cd face_scrapper

Next, you will create a virtual environment for this project. Virtual environments isolate different projects so that differing dependencies won’t cause any disruptions. Create a virtual environment named `face_scrapper` to use with this project:

    python3 -m venv face_scrapper

Activate the isolated environment:

    source face_scrapper/bin/activate

You will now see that your prompt is prefixed with the name of your virtual environment:

    

Now that you’ve activated your virtual environment, you will use `nano` or your favorite text editor to create a `requirements.txt` file. This file indicates the necessary Python dependencies:

    nano requirements.txt

Next, you need to install three dependencies to complete this tutorial:

- `numpy`: [numpy](https://en.wikipedia.org/wiki/NumPy) is a Python library that adds support for large, multi-dimensional arrays. It also includes a large collection of mathematical functions to operate on the arrays.
- `opencv-utils`: This is the extended library for OpenCV that includes helper functions.
- `opencv-python`: This is the core OpenCV module that Python uses.

Add the following dependencies to the file:

requirements.txt

    numpy 
    opencv-utils
    opencv-python

Save and close the file.

Install the dependencies by passing the `requirements.txt` file to the Python package manager, `pip`. The `-r` flag specifies the location of `requirements.txt` file.

    pip install -r requirements.txt

In this step, you set up a virtual environment for your project and installed the necessary dependencies. You’re now ready to start writing the code to detect faces from an input image in next step.

## Step 2 — Writing and Running the Face Detector Script

In this section, you will write code that will take an image as input and return two things:

- The number of faces found in the input image.
- A new image with a rectangular plot around each detected face. 

Start by creating a new file to hold your code:

    nano app.py

In this new file, start writing your code by first importing the necessary libraries. You will import two modules here: `cv2` and `sys`. The `cv2` module imports the `OpenCV` library into the program, and `sys` imports common Python functions, such as `argv`, that your code will use.

app.py

    import cv2
    import sys

Next, you will specify that the input image will be passed as an argument to the script at runtime. The Pythonic way of reading the first argument is to assign the value returned by `sys.argv[1]` function to an variable:

app.py

    ...
    imagePath = sys.argv[1]

A common practice in image processing is to first convert the input image to gray scale. This is because detecting luminance, as opposed to color, will generally yield better results in object detection. Add the following code to take an input image as an argument and convert it to grayscale:

app.py

    ...
    image = cv2.imread(imagePath)
    gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)

The `.imread()` function takes the input image, which is passed as an argument to the script, and converts it to an OpenCV object. Next, OpenCV’s `.cvtColor()` function converts the input image object to a grayscale object.

Now that you’ve added the code to load an image, you will add the code that detects faces in the specified image:

app.py

    ...
    faceCascade = cv2.CascadeClassifier(cv2.data.haarcascades + "haarcascade_frontalface_default.xml")
    faces = faceCascade.detectMultiScale(
            gray,
            scaleFactor=1.3,
            minNeighbors=3,
            minSize=(30, 30)
    ) 
    
    print("Found {0} Faces!".format(len(faces)))
    

This code will create a `faceCascade` object that will load the Haar Cascade file with the `cv2.CascadeClassifier` method. This allows Python and your code to use the Haar Cascade.

Next, the code applies OpenCV’s `.detectMultiScale()` method on the `faceCascade` object. This generates a _list of rectangles_ for all of the detected faces in the image. The list of rectangles is a collection of pixel locations from the image, in the form of `Rect(x,y,w,h)`.

Here is a summary of the other parameters your code uses:

- `gray`: This specifies the use of the OpenCV grayscale image object that you loaded earlier. 
- `scaleFactor`: This parameter specifies the rate to reduce the image size at each image scale. Your model has a fixed scale during training, so input images can be scaled down for improved detection. This process stops after reaching a threshold limit, defined by `maxSize` and `minSize`. 
- `minNeighbors`: This parameter specifies how many neighbors, or detections, each candidate rectangle should have to retain it. A higher value may result in less false positives, but a value too high can eliminate true positives. 
- `minSize`: This allows you to define the minimum possible object size measured in pixels. Objects smaller than this parameter are ignored.

After generating a list of rectangles, the faces are then counted with the `len` function. The number of detected faces are then returned as output after running the script.

Next, you will use OpenCV’s `.rectangle()` method to draw a rectangle around the detected faces:

app.py

    ...
    for (x, y, w, h) in faces:
        cv2.rectangle(image, (x, y), (x+w, y+h), (0, 255, 0), 2)
    

This code uses a _for loop_ to iterate through the list of pixel locations returned from `faceCascade.detectMultiScale` method for each detected object. The `rectangle` method will take four arguments:

- `image` tells the code to draw rectangles on the original input image.
- `(x,y), (x+w, y+h)` are the four pixel locations for the detected object. `rectangle` will use these to locate and draw rectangles around the detected objects in the input image.
- `(0, 255, 0)` is the color of the shape. This argument gets passed as a tuple for BGR. For example, you would use `(255, 0, 0)` for blue. We are using green in this case.
- `2` is the thickness of the line measured in pixels. 

Now that you’ve added the code to draw the rectangles, use OpenCV’s `.imwrite()` method to write the new image to your local filesystem as `faces_detected.jpg`. This method will return `true` if the write was successful and `false` if it wasn’t able to write the new image.

app.py

    ...
    status = cv2.imwrite('faces_detected.jpg', image)

Finally, add this code to print the return the `true` or `false` status of the `.imwrite()` function to the console. This will let you know if the write was successful after running the script.

app.py

    ...
    print ("Image faces_detected.jpg written to filesystem: ",status)

The completed file will look like this:

app.py

    import cv2
    import sys
    
    imagePath = sys.argv[1]
    
    image = cv2.imread(imagePath)
    gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
    
    faceCascade = cv2.CascadeClassifier(cv2.data.haarcascades + "haarcascade_frontalface_default.xml")
    faces = faceCascade.detectMultiScale(
        gray,
        scaleFactor=1.3,
        minNeighbors=3,
        minSize=(30, 30)
    )
    
    print("[INFO] Found {0} Faces!".format(len(faces)))
    
    for (x, y, w, h) in faces:
        cv2.rectangle(image, (x, y), (x + w, y + h), (0, 255, 0), 2)
    
    status = cv2.imwrite('faces_detected.jpg', image)
    print("[INFO] Image faces_detected.jpg written to filesystem: ", status)

Once you’ve verified that everything is entered correctly, save and close the file.

**Note:** This code was sourced from the publicly available [OpenCV documentation](https://docs.opencv.org/3.4/db/d28/tutorial_cascade_classifier.html).

Your code is complete and you are ready to run the script.

## Step 3 — Running the Script

In this step, you will use an image to test your script. When you find an image you’d like to use to test, save it in the same directory as your `app.py` script. This tutorial will use the following image:

![Input Image of four people looking at phones](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/CART-63965/people_with_phones.png)

If you would like to test with the same image, use the following command to download it:

    curl -O https://assets.digitalocean.com/articles/CART-63965/people_with_phones.png

Once you have an image to test the script, run the script and provide the image path as an argument:

    python app.py path/to/input_image

Once the script finishes running, you will receive output like this:

    Output[INFO] Found 4 Faces!
    [INFO] Image faces_detected.jpg written to filesystem: True

The `true` output tells you that the updated image was successfully written to the filesystem. Open the image on your local machine to see the changes on the new file:

![Output Image with detected faces](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/CART-63965/people_with_phones_detection.png)

You should see that your script detected four faces in the input image and drew rectangles to mark them. In the next step, you will use the pixel locations to extract faces from the image.

## Step 4 — Extracting Faces and Saving them Locally (Optional)

In the previous step, you wrote code to use OpenCV and a Haar Cascade to detect and draw rectangles around faces in an image. In this section, you will modify your code to extract the detected faces from the image into their own files.

Start by reopening the `app.py` file with your text editor:

    nano app.py

Next, add the highlighted lines under the `cv2.rectangle` line:

app.py

    ...
    for (x, y, w, h) in faces:
        cv2.rectangle(image, (x, y), (x + w, y + h), (0, 255, 0), 2)
        roi_color = image[y:y + h, x:x + w] 
        print("[INFO] Object found. Saving locally.") 
        cv2.imwrite(str(w) + str(h) + '_faces.jpg', roi_color) 
    ...

The `roi_color` object plots the pixel locations from the `faces` list on the original input image. The `x`, `y`, `h`, and `w` variables are the pixel locations for each of the objects detected from `faceCascade.detectMultiScale` method. The code then prints output stating that an object was found and will be saved locally.

Once that is done, the code saves the plot as a new image using the `cv2.imwrite` method. It appends the width and height of the plot to the name of the image being written to. This will keep the name unique in case there are multiple faces detected.

The updated `app.py` script will look like this:

app.py

    import cv2
    import sys
    
    imagePath = sys.argv[1]
    
    image = cv2.imread(imagePath)
    gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
    
    faceCascade = cv2.CascadeClassifier(cv2.data.haarcascades + "haarcascade_frontalface_default.xml")
    faces = faceCascade.detectMultiScale(
        gray,
        scaleFactor=1.3,
        minNeighbors=3,
        minSize=(30, 30)
    )
    
    print("[INFO] Found {0} Faces.".format(len(faces)))
    
    for (x, y, w, h) in faces:
        cv2.rectangle(image, (x, y), (x + w, y + h), (0, 255, 0), 2)
        roi_color = image[y:y + h, x:x + w]
        print("[INFO] Object found. Saving locally.")
        cv2.imwrite(str(w) + str(h) + '_faces.jpg', roi_color)
    
    status = cv2.imwrite('faces_detected.jpg', image)
    print("[INFO] Image faces_detected.jpg written to filesystem: ", status)

To summarize, the updated code uses the pixel locations to extract the faces from the image into a new file. Once you have finished updating the code, save and close the file.

Now that you’ve updated the code, you are ready to run the script once more:

    python app.py path/to/image

You will see the similar output once your script is done processing the image:

    Output[INFO] Found 4 Faces.
    [INFO] Object found. Saving locally.
    [INFO] Object found. Saving locally.
    [INFO] Object found. Saving locally.
    [INFO] Object found. Saving locally.
    [INFO] Image faces_detected.jpg written to file-system: True

Depending on how many faces are in your sample image, you may see more or less output.

Looking at the contents of the working directory after the execution of the script, you’ll see files for the head shots of all faces found in the input image.

![Directory Listing](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/CART-63965/directory.png)

You will now see head shots extracted from the input image collected in the working directory:

![Extracted Faces](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/CART-63965/extracted_faces.png)

In this step, you modified your script to extract the detected objects from the input image and save them locally.

## Conclusion

In this tutorial, you wrote a script that uses OpenCV and Python to detect, count, and extract faces from an input image. You can update this script to detect different objects by using a different pre-trained Haar Cascade from the OpenCV library, or you can learn how to [train your own](https://docs.opencv.org/3.3.0/dc/d88/tutorial_traincascade.html) Haar Cascade.
