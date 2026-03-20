function daVinciNotebook(input_path, output_path, random_seed)
% daVinciNotebook - Converts a photograph into a da Vinci-style aged notebook sketch
%
% USAGE:
%   daVinciNotebook('photo.jpg')
%   daVinciNotebook('photo.jpg', 'output.png')
%   daVinciNotebook('photo.jpg', 'output.png', 42)
%
% INPUTS:
%   input_path  - (required) path to your input image file
%   output_path - (optional) path for saved output, default: 'notebook_effect.png'
%   random_seed - (optional) integer seed for reproducible aging effects
%                 use 'shuffle' or omit for a different result each run
%
% EXAMPLES:
%   daVinciNotebook('portrait.jpg')
%   daVinciNotebook('portrait.jpg', 'my_notebook.png', 7)

    %% =====================
    %  Handle default arguments
    %% =====================
    if nargin < 1
        error('daVinciNotebook requires at least one argument: input image path.');
    end
    if nargin < 2 || isempty(output_path)
        output_path = 'notebook_effect.png';
    end
    if nargin < 3
        rng('shuffle');     % different result each run by default
    else
        rng(random_seed);   % fixed seed for reproducibility
    end

    %% =====================
    %  STEP 1: Load & Prepare
    %% =====================
    fprintf('Loading image: %s\n', input_path);
    f = imread(input_path);

    % Handle grayscale input images
    if size(f, 3) == 1
        f = cat(3, f, f, f);
    end

    gray = rgb2gray(f);
    gray = double(gray);
    [rows, cols, ~] = size(f);

    %% =====================
    %  STEP 2: Pencil Sketch
    %% =====================
    fprintf('Generating pencil sketch...\n');

    % Gaussian blur to reduce noise before edge detection
    w_gauss = fspecial('Gaussian', [5 5], 1.0);
    smoothed = imfilter(gray, w_gauss, 'replicate');

    % Sobel edge detection in both directions
    sobel_h = fspecial('sobel');
    sobel_v = sobel_h';
    edges_h = imfilter(smoothed, sobel_h, 'replicate');
    edges_v = imfilter(smoothed, sobel_v, 'replicate');
    edges = sqrt(edges_h.^2 + edges_v.^2);

    % Normalise and invert: white background, dark lines
    edges = edges / max(edges(:));
    sketch = 1 - edges;

    % Sharpen sketch lines with contrast stretch (Lab 3 technique)
    sketch = imadjust(sketch, [0.7 1.0], [0 1]);

    %% =====================
    %  STEP 3: Sepia Tone + Brown Line Tinge
    %% =====================
    fprintf('Applying sepia tone...\n');

    R = sketch * 240;
    G = sketch * 200;
    B = sketch * 150;
    sepia = cat(3, uint8(R), uint8(G), uint8(B));

    % Give dark lines a warm brown tinge
    % 'darkness' is 1.0 where lines are darkest, 0.0 on white background
    darkness = 1 - sketch;

    % Target brown colour for the darkest lines (R=101, G=55, B=20)
    brown_R = 101;
    brown_G = 55;
    brown_B = 20;

    % Blend each channel toward brown in proportion to how dark the pixel is
    sepia_R = double(sepia(:,:,1)) .* (1 - darkness) + brown_R .* darkness;
    sepia_G = double(sepia(:,:,2)) .* (1 - darkness) + brown_G .* darkness;
    sepia_B = double(sepia(:,:,3)) .* (1 - darkness) + brown_B .* darkness;

    sepia = cat(3, uint8(sepia_R), uint8(sepia_G), uint8(sepia_B));

    %% =====================
    %  STEP 4: Paper Texture (Synthesised)
    %% =====================
    fprintf('Synthesising paper texture...\n');

    % Generate base paper grain noise
    grain = randn(rows, cols) * 12;

    % Smooth grain to look like paper fibre
    w_paper = fspecial('Gaussian', [15 15], 3.0);
    grain = imfilter(grain, w_paper, 'replicate');

    % Normalise grain to subtle range [0.85, 1.0]
    grain = grain - min(grain(:));
    grain = grain / max(grain(:));
    grain = grain * 0.15 + 0.85;

    % Apply grain to each sepia channel
    paper = zeros(rows, cols, 3, 'uint8');
    for ch = 1:3
        channel = double(sepia(:,:,ch)) .* grain;
        paper(:,:,ch) = uint8(min(channel, 255));
    end

    %% =====================
    %  STEP 5: Randomised Aging - Blotches & Fading
    %% =====================
    fprintf('Applying randomised aging effects...\n');

    % --- Ink blotches (random dark spots using dilation - Lab 4 technique) ---
    num_blotches = 8;
    blotch_mask = zeros(rows, cols);
    for i = 1:num_blotches
        rx = randi([50, rows-50]);
        cx = randi([50, cols-50]);
        blotch_mask(rx, cx) = 1;
    end
    SE_blotch = strel('disk', randi([3 10]));
    blotch_mask = imdilate(blotch_mask, SE_blotch);
    blotch_mask = imfilter(double(blotch_mask), fspecial('Gaussian', [9 9], 2));
    blotch_mask = 1 - (blotch_mask * 0.4);

    % --- Random fading patches (bright washed-out areas) ---
    fade_mask = ones(rows, cols);
    num_fades = 5;
    for i = 1:num_fades
        rx = randi([1, rows]);
        cx = randi([1, cols]);
        fade_radius = randi([30, 100]);
        [Xf, Yf] = meshgrid(1:cols, 1:rows);
        fade_patch = exp(-((Xf-cx).^2 + (Yf-rx).^2) / (2 * fade_radius^2));
        fade_mask = fade_mask + fade_patch * 0.3;
    end
    fade_mask = min(fade_mask, 1.25);

    % Combine masks and apply
    aging_mask = blotch_mask .* fade_mask;
    aged = zeros(rows, cols, 3, 'uint8');
    for ch = 1:3
        aged(:,:,ch) = uint8(min(double(paper(:,:,ch)) .* aging_mask, 255));
    end

    %% =====================
    %  STEP 6: Crease Lines
    %% =====================
    fprintf('Adding crease lines...\n');

    crease = zeros(rows, cols);
    num_creases = 3;
    for i = 1:num_creases
        start_r = randi([1, rows]);
        start_c = randi([1, cols]);
        angle   = rand() * pi;
        for t = -max(rows, cols):max(rows, cols)
            r = round(start_r + t * sin(angle));
            c = round(start_c + t * cos(angle));
            if r >= 1 && r <= rows && c >= 1 && c <= cols
                crease(r, c) = 1;
            end
        end
    end
    crease = imfilter(crease, fspecial('Gaussian', [3 3], 0.8));
    crease = crease / max(crease(:)) * 0.15;

    final = zeros(rows, cols, 3, 'uint8');
    for ch = 1:3
        final(:,:,ch) = uint8(min(double(aged(:,:,ch)) + crease * 255, 255));
    end

    %% =====================
    %  STEP 7: Subtle Skew (Lab 1 technique via imwarp)
    %% =====================
    fprintf('Applying subtle skew...\n');

    tform = affine2d([1,    0.02, 0;
                      0.01, 1,   0;
                      0,    0,   1]);
    final = imwarp(final, tform, 'OutputView', imref2d(size(final)));

    %% =====================
    %  STEP 8: Display & Save
    %% =====================
    fprintf('Displaying results...\n');

    figure('Name', 'Da Vinci Notebook Effect', 'NumberTitle', 'off');
    imshow(final)

    imwrite(final, output_path);
    fprintf('Done! Result saved to: %s\n', output_path);

end
