function halftoneImage(input_path, output_path, dot_size, style)
% halftoneImage - Converts a photograph into a halftone dot pattern image
%
% USAGE:
%   halftoneImage('photo.jpg')
%   halftoneImage('photo.jpg', 'output.png')
%   halftoneImage('photo.jpg', 'output.png', 10)
%   halftoneImage('photo.jpg', 'output.png', 10, 'newspaper')
%
% INPUTS:
%   input_path  - (required) path to your input image file
%   output_path - (optional) path for saved output, default: 'halftone_effect.png'
%   dot_size    - (optional) grid cell size in pixels, controls dot density
%                 smaller = finer dots, larger = coarser dots (default: 10)
%   style       - (optional) halftone style string, one of:
%                   'classic'    - black dots on white background (default)
%                   'newspaper'  - aged yellowed newspaper look
%                   'colour'     - coloured dots per RGB channel
%                   'inverted'   - white dots on black background
%
% EXAMPLES:
%   halftoneImage('portrait.jpg')
%   halftoneImage('portrait.jpg', 'halftone.png', 8, 'newspaper')
%   halftoneImage('portrait.jpg', 'halftone.png', 12, 'colour')

    %% =====================
    %  Handle default arguments
    %% =====================
    if nargin < 1
        error('halftoneImage requires at least one argument: input image path.');
    end
    if nargin < 2 || isempty(output_path)
        output_path = 'halftone_effect.png';
    end
    if nargin < 3 || isempty(dot_size)
        dot_size = 10;
    end
    if nargin < 4 || isempty(style)
        style = 'classic';
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
    gray = double(rgb2gray(f)) / 255;   % normalise to [0, 1]

    %% =====================
    %  STEP 2: Pre-blur to reduce noise
    %% =====================
    fprintf('Pre-processing image...\n');

    w_gauss = fspecial('Gaussian', [5 5], 1.5);
    gray = imfilter(gray, w_gauss, 'replicate');

    %% =====================
    %  STEP 2b: High Contrast Enhancement
    %% =====================
    fprintf('Enhancing contrast...\n');

    % Histogram equalisation to spread the tonal range fully
    gray_uint8 = uint8(gray * 255);
    gray_uint8 = histeq(gray_uint8, 256);
    gray = double(gray_uint8) / 255;

    % Aggressive S-curve via gamma correction - pushes darks darker,
    % lights lighter, maximising separation between tones
    gray = imadjust(gray, [0.15 0.85], [0 1], 0.6);

    % Final hard clip - anything below 20% brightness snaps to black,
    % anything above 80% snaps to white, eliminating muddy mid-greys
    gray = (gray - 0.2) / (0.8 - 0.2);
    gray = min(max(gray, 0), 1);

    %% =====================
    %  STEP 3: Build halftone grid
    %% =====================
    fprintf('Generating halftone dots...\n');

    % Output canvas - start white
    canvas = ones(rows, cols);

    half = floor(dot_size / 2);     % half cell size for centring dots

    % Step through image in grid cells of dot_size x dot_size
    for r = 1:dot_size:rows
        for c = 1:dot_size:cols

            % Define the boundary of this grid cell
            r1 = r;
            r2 = min(r + dot_size - 1, rows);
            c1 = c;
            c2 = min(c + dot_size - 1, cols);

            % Sample the average brightness of this cell
            cell = gray(r1:r2, c1:c2);
            brightness = mean(cell(:));     % 0 = black, 1 = white

            % Dot radius scales inversely with brightness
            % dark areas = large dots, bright areas = small dots
            max_radius = half * 0.95;
            dot_radius = max_radius * (1 - brightness);

            % Find centre of this cell
            cr = round((r1 + r2) / 2);
            cc = round((c1 + c2) / 2);

            % Draw filled circle at this cell centre
            for pr = r1:r2
                for pc = c1:c2
                    dist = sqrt((pr - cr)^2 + (pc - cc)^2);
                    if dist <= dot_radius
                        canvas(pr, pc) = 0;     % paint dot black
                    end
                end
            end

        end
    end

    %% =====================
    %  STEP 4: Apply style
    %% =====================
    fprintf('Applying style: %s\n', style);

    switch lower(style)

        case 'classic'
            % Black dots on clean white background
            output = repmat(uint8(canvas * 255), [1 1 3]);

        case 'newspaper'
            % Aged yellow-cream paper with dark brown dots
            paper_R = canvas * 235 + (1 - canvas) * 80;
            paper_G = canvas * 220 + (1 - canvas) * 50;
            paper_B = canvas * 180 + (1 - canvas) * 20;

            % Add subtle paper grain noise
            grain = randn(rows, cols) * 6;
            w_grain = fspecial('Gaussian', [7 7], 2.0);
            grain = imfilter(grain, w_grain, 'replicate');

            paper_R = paper_R + grain;
            paper_G = paper_G + grain * 0.9;
            paper_B = paper_B + grain * 0.7;

            output = cat(3, uint8(min(max(paper_R, 0), 255)), ...
                            uint8(min(max(paper_G, 0), 255)), ...
                            uint8(min(max(paper_B, 0), 255)));

        case 'colour'
            % Separate halftone per R, G, B channel with slight grid offsets
            % to mimic real CMYK printing registration
            f_double = double(f) / 255;
            output_R = ones(rows, cols);
            output_G = ones(rows, cols);
            output_B = ones(rows, cols);

            offsets = [0, 2, 4];    % slight grid offset per channel

            channels = {f_double(:,:,1), f_double(:,:,2), f_double(:,:,3)};
            outputs  = {output_R, output_G, output_B};

            for ch = 1:3
                chan   = imfilter(channels{ch}, w_gauss, 'replicate');
                offset = offsets(ch);
                for r = 1:dot_size:rows
                    for c = 1:dot_size:cols
                        r1 = min(r + offset, rows);
                        r2 = min(r + dot_size - 1 + offset, rows);
                        c1 = min(c + offset, cols);
                        c2 = min(c + dot_size - 1 + offset, cols);

                        cell       = chan(r1:r2, c1:c2);
                        brightness = mean(cell(:));
                        dot_radius = half * 0.95 * (1 - brightness);

                        cr = round((r1 + r2) / 2);
                        cc = round((c1 + c2) / 2);

                        for pr = r1:r2
                            for pc = c1:c2
                                dist = sqrt((pr - cr)^2 + (pc - cc)^2);
                                if dist <= dot_radius
                                    outputs{ch}(pr, pc) = 0;
                                end
                            end
                        end
                    end
                end
            end

            % Composite: white where all channels are white, colour where dots fall
            out_R = uint8(outputs{1} * 255);
            out_G = uint8(outputs{2} * 255);
            out_B = uint8(outputs{3} * 255);
            output = cat(3, out_R, out_G, out_B);

        case 'inverted'
            % White dots on black background
            inverted = 1 - canvas;
            output = repmat(uint8(inverted * 255), [1 1 3]);

        otherwise
            warning('Unknown style "%s". Defaulting to classic.', style);
            output = repmat(uint8(canvas * 255), [1 1 3]);

    end

    %% =====================
    %  STEP 5: Display & Save
    %% =====================
    fprintf('Displaying results...\n');

    figure('Name', 'Halftone Effect', 'NumberTitle', 'off');
    imshow(output)

    imwrite(output, output_path);
    fprintf('Done! Result saved to: %s\n', output_path);

end
