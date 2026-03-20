# DVS Project_LisaPayal

# Conveying Information Through History

**Theme: ‘Artify’ Images**

### **Aim:**

Images have been a key part of conveying images through history. This project explores how a single photograph can be transformed into different visual styles that represent key stages in the evolution of image-making. The goal is to interpret the same scene through:

- Hand-drawn Images
- Early photographs
- Television screens
- The Computer Era

By doing so, the project highlights how visual representation has evolved from mechanical reproduction to computational abstraction. 

### **Concept:**

The idea behind this project was to move beyond treating “artification” as a single stylistic filter and instead frame it as a timeline of visual representation. A single photograph is reinterpreted across four distinct eras, manual, mechanical, signal, and digital, each reflecting how images were constructed, constrained, and perceived within its medium. Through this progression, the project explores how the same visual reality can be translated differently, not just stylistically, but fundamentally, depending on the system used to represent it.

### Visual Progression:

The transformation of the image is presented as a sequential reinterpretation across different modes of visual representation:

#### Original Image:

The starting point is a high-resolution digital photograph that represents reality as captured by modern imaging systems. It preserves full colour, detail, and continuous tonal variation.


![[tree.jpeg|320]]
## Unknown - 1800s - The Handmade Era

While the printing press marked the first source of mass-distributed texts, production of imagery up until the 1800’s was primarily hand-made, either through drawings or hand-cut blocks. The source that inspired us for the hand-drawn images was the notebooks of Leonardo daVinci from the Renaissance era.

![[da_vinci.png]]

**MATLAB approach:**

The image is first converted to grayscale using `rgb2gray`, then smoothed with `imfilter` and a Gaussian kernel to reduce noise. Contours are extracted using Sobel filters (`fspecial('sobel')` with `imfilter`) and combined to form an edge map, which is inverted and enhanced using `imadjust` to produce a sketch-like effect. Sepia tones are applied using channel scaling (`cat`), while paper texture is generated using `randn` and `imfilter`. Aging effects such as blotches (`imdilate`) and slight distortion (`imwarp`) are added to simulate an old notebook surface.

**What’s happening conceptually:**

- Edge detection → contour extraction
- Contrast enhancement → sharpen lines
- Sepia mapping → aged tone
- Texture synthesis → paper effect
- Random aging → imperfections

**Output:**
![[notebook_guide.jpg]]

# 1800s - Birth of Photography

The 19th Century was marked by the invention of photography humans could finally preserve physical moments across time. Using the halftone printing method the image is further transformed into a pattern composed of dots.

![[image.png]]
**MATLAB approach:**

The image is converted to grayscale (`rgb2gray`) and pre-processed using Gaussian smoothing (`imfilter`) to reduce noise. Contrast is enhanced using `histeq` and `imadjust` to clearly separate tonal regions. The image is then divided into small cells, where the average intensity (`mean`) determines the size of circular dots, computed using distance (`sqrt`). This replaces continuous tones with dot patterns, replicating mechanical printing techniques.

**What’s happening conceptually:**

- Convert to grayscale
- Divide image into small cells
- Replace each cell with a dot based on intensity

**Output:**

![[halfton_guide.png]]


# 1900s - Television


![[tv.png]]
**MATLAB Approach:**

The next stage simulates an early black-and-white screen aesthetic, where the image is no longer printed but electronically displayed. The image is converted to grayscale with `rgb2gray`, contrast is pushed using `histeq` and `imadjust`, and resolution is reshaped using `imresize` to mimic a low-resolution display. A 1-bit dithered effect is then created through thresholding and error diffusion, while screen characteristics such as scan lines, phosphor glow, static noise, curvature, and vignette are added using `fspecial('Gaussian')`, `imfilter`, `interp2`, and `randn`. This stage reflects how images began to be experienced through screens rather than paper

**What’s happening conceptually:**

- Convert to grayscale
- Reduce resolution to simulate screen display
- Apply dithering to mimic limited tonal depth
- Introduce scan lines and noise
- Add screen curvature and vignette

Output: 
![[tv_guide.png]]
# 2000s The Internet Age

![[computer.jpg|320]]


Early internet images were experiments in compression, leading to a plethora of small-size pixellated images .The image here is transformed into a pixelated form. where visual cues are reduced into grids of discrete units. Fine details are lost with emphasis on primary elements of the image, making the image a structured matrix of values.

**MATLAB approach:**

Here, the image is reduced to a pixelated form, representing how digital systems encode visual information. Contrast and colour are first enhanced using `histeq`, `imadjust`, and colour space transformations (`rgb2hsv`, `hsv2rgb`). The image is then simplified into a limited set of colours using clustering (`imsegkmeans`). It is further divided into blocks, where each block is replaced with its average colour (`mean`), creating a grid-like structure. This stage reflects how images are treated as **discrete data units**, rather than continuous visuals.

**What’s happening conceptually:**

- Continuous image → discrete sampling
- Detail → lost due to resolution reduction
- Structure → represented as a matrix

**Output:**
![[pixel_guide.png]]

## Final Output: Artify Montage

`artifyMontage` is a MATLAB function we created that processes a single photograph through four visual era filters — da Vinci, Halftone, Television, and Pixellated — and displays all five images side by side in one output. To use it, ensure all function files are in the same folder and call:

```jsx
artifyMontage('photo.jpg')
```
![[artify_montage.png]]

Working on the da Vinci notebook effect for the hand-drawn era  introduced the core MATLAB image processing pipeline. Combining imfilter with Sobel kernels for edge extraction, imadjust for contrast stretching, and randn with Gaussian smoothing for texture synthesis established the foundational pattern of convert, enhance, and composite that all subsequent functions built upon.
For the newspaper era the halftone function taught us how to spatially subdivide an image matrix into cells and make decisions based on local statistics using mean. Mapping average intensity to dot radius introduced the idea of encoding continuous tonal information as a discrete geometric property. The television effect introduced coordinate-space transformations. Using meshgrid and interp2 to implement barrel distortion showed how pixel remapping works at a matrix level. Generating scan lines through row-indexed masking and simulating signal noise with weighted randn demonstrated how physical screen artefacts translate directly into matrix operations.
Finally, the pixellation function introduced imsegkmeans for k-means clustering, showing how unsupervised grouping reduces a continuous colour space to discrete representative values. Combining this with block averaging via nested loops reinforced how digital images are fundamentally sampled, discrete structures rather than continuous ones.

#### Evaluation

#### What works well

- Successfully recreates distinct visual styles across historical eras
- Modular MATLAB functions allow easy reuse and extension
- Outputs clearly demonstrate different modes of image representation
- Strong visual differentiation between each stage

#### Limitations

- Performance depends on input image quality (low contrast → weaker outputs)
- Fine details are lost in halftone and pixelation stages
- TV effect is a stylised approximation, not physically accurate
- Fixed parameters may not generalise well across all images

#### **Division of Work:**

This project was developed collaboratively, with both members contributing across concept, implementation, and refinement, while taking lead roles in specific areas

**Shared Contributions:**

- Co-developed the project concept of “Artifying Images Through History”
- Jointly defined the visual progression across all styles
- Collaborated on MATLAB implementation for each transformation
- Explored and applied image processing techniques (filtering, edge detection, clustering, etc.)
- Iteratively refined outputs for both technical accuracy and visual quality
- Worked together on testing, debugging, and parameter tuning
- Co-created the final report, structure, and visual presentation

#### **Individual Contributions**

**Lisa Pinto | CID: 06054061**

- Focused on strengthening the technical implementation and optimisation
- Contributed to improving code structure, parameter tuning, and execution
- Assisted in ensuring robustness and reproducibility of outputs

**Payal Chand | CID: 06067958**

- Focused on shaping the design narrative and conceptual framing
- Led the structuring of the visual progression and written explanation
- Contributed to refining outputs for aesthetic clarity and consistency