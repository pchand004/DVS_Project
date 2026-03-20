function pixellateImage(input_path, output_path, pixel_size, contrast_strength)
% pixellateImage - Converts a photograph into a high-contrast pixellated artwork
%
% USAGE:
%   pixellateImage('photo.jpg')
%   pixellateImage('photo.jpg', 'output.png')
%   pixellateImage('photo.jpg', 'output.png', 12)
%   pixellateImage('photo.jpg', 'output.png', 12, 1.5)
%
% INPUTS:
%   input_path        - (required) path to your input image file
%   output_path       - (optional) output file path, default: 'pixellated.png'
%   pixel_size        - (optional) size of each pixel block in pixels, default: 12
%                       smaller = finer detail, larger = chunkier retro look
%   contrast_strength - (optional) gamma value for contrast curve, default: 1.5
%                       higher = more aggressive contrast boost
%
% EXAMPLES:
%   pixellateImage('portrait.jpg')
%   pixellateImage('portrait.jpg', 'pixel.png', 16)
%   pixellateImage('portrait.jpg', 'pixel.png', 8, 2.0)

    %% =====================
    %  Handle default arguments
    %% =====================
    if nargin < 1
        error('pixellateImage requires at least one argument: input image path.');
    end
    if nargin < 2 || isempty(output_path)
        output_path = 'pixellated.png';
    end
    if nargin < 3 || isempty(pixel_size)
        pixel_size = 12;
    end
    if nargin < 4 || isempty(contrast_strength)
        contrast_strength = 1.5;
    end

    %% =====================
    %  STEP 1: Load & Prepare
    %% =====================
    fprintf('Loading image: %s\n', input_path);
    f = imread(input_path);

    % Handle grayscale input
    if size(f, 3) == 1
        f = cat(3, f, f, f);
    end

    [rows, cols, ~] = size(f);

    %% =====================
    %  STEP 2: Contrast Enhancement
    %% =====================
    fprintf('Enhancing contrast...\n');

    f_double = double(f) / 255;

    % Histogram equalisation per channel to maximise tonal range
    f_eq = zeros(size(f_double));
    for ch = 1:3
        chan          = uint8(f_double(:,:,ch) * 255);
        f_eq(:,:,ch)  = double(histeq(chan, 256)) / 255;
    end

    % Aggressive S-curve: pushes darks darker, lights lighter
    f_contrast = imadjust(f_eq, [0.1 0.9], [0 1], 1/contrast_strength);

    % Saturate colours - increase separation between hues
    f_hsv              = rgb2hsv(f_contrast);
    f_hsv(:,:,2)       = min(f_hsv(:,:,2) * 1.6, 1.0);   % boost saturation
    f_hsv(:,:,3)       = imadjust(f_hsv(:,:,3), [0.1 0.9], [0 1]);
    f_saturated        = hsv2rgb(f_hsv);
    f_saturated        = min(max(f_saturated, 0), 1);

    %% =====================
    %  STEP 3: Reduce to 16 colours using k-means clustering (Lab 5 Task 5)
    %% =====================
    fprintf('Reducing to 16 colours with k-means clustering...\n');

    % Reshape image from 2D grid of RGB pixels into 1D list of RGB vectors
    % matching exactly the Lab 5 technique: reshape(f, [M*N S])
    f_uint8  = uint8(f_saturated * 255);
    [M, N, S] = size(f_uint8);

    % imsegkmeans performs k-means clustering directly on the image
    % L is the label matrix - each pixel assigned a cluster index 1..16
    % centers contains the mean RGB colour for each of the 16 clusters
    k = 16;
    [L, centers] = imsegkmeans(f_uint8, k);

    % label2rgb maps each label back to its cluster mean colour
    % producing a flat-colour image with exactly 16 distinct colours
    f_16col = im2double(label2rgb(L, im2double(centers)));

    %% =====================
    %  STEP 4: Pixellate
    %  Average colour within each block, then flood-fill entire block
    %% =====================
    fprintf('Pixellating with block size %d...\n', pixel_size);

    f_pixellated = f_16col;

    for r = 1:pixel_size:rows
        for c = 1:pixel_size:cols

            % Define block boundaries
            r1 = r;
            r2 = min(r + pixel_size - 1, rows);
            c1 = c;
            c2 = min(c + pixel_size - 1, cols);

            % Compute average colour of block for each channel
            for ch = 1:3
                block     = f_16col(r1:r2, c1:c2, ch);
                avg_color = mean(block(:));
                f_pixellated(r1:r2, c1:c2, ch) = avg_color;
            end

        end
    end

    %% =====================
    %  STEP 5: Display & Save
    %% =====================
    fprintf('Displaying results...\n');

    final_uint8 = uint8(min(max(f_pixellated, 0), 1) * 255);

    figure('Name', 'Pixellate Effect', 'NumberTitle', 'off');
    imshow(final_uint8)

    imwrite(final_uint8, output_path);
    fprintf('Done! Result saved to: %s\n', output_path);

end
