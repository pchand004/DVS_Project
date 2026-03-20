function tvSixties(input_path, output_path, strength)

    
    %  Handle default arguments

    if nargin < 1
        error('tvSixties requires at least one argument: input image path.');
    end
    if nargin < 2 || isempty(output_path)
        output_path = 'tvSixties.png';
    end
    if nargin < 3 || isempty(strength)
        strength = 0.8;
    end


    %  STEP 1: Load & convert to grayscale

    fprintf('Loading image: %s\n', input_path);
    f = imread(input_path);

    if size(f, 3) == 1
        f = cat(3, f, f, f);
    end

    [rows, cols, ~] = size(f);
    gray = double(rgb2gray(f)) / 255;


    %  STEP 2: Contrast boost
    %  These screens had very stark contrast - almost no midtones
    fprintf('Boosting contrast...\n');

    gray = double(histeq(uint8(gray * 255))) / 255;

    % Very aggressive S-curve - pushes toward pure black or pure white
    % mimicking the limited tonal range of early displays
    gray = imadjust(gray, [0.2 0.8], [0 1], 0.6);

    
    %  STEP 3: Downscale to tv resolution then upscale
    %  We scale down to that resolution then scale back up to preserve
    %  the chunky blocky pixel look on modern displays
    
    fprintf('Applying tv pixel resolution...\n');

    tv_w = 512;
    tv_h = 342;

    % Downscale to native resolution
    gray_small = imresize(gray, [tv_h tv_w], 'bilinear');

    % Upscale back to original size using nearest-neighbour
    % to get hard blocky pixel edges rather than smooth blending
    gray = imresize(gray_small, [rows cols], 'nearest');

    
    %  STEP 4: Floyd-Steinberg error diffusion dithering
    %  Error diffusion dithering gives the characteristic halftone look
    
    fprintf('Applying 1-bit dithering...\n');

    dithered = gray;    % work on a copy

    for r = 1:rows
        for c = 1:cols
            old_val = dithered(r, c);
            % Quantise to pure black (0) or pure white (1)
            new_val = double(old_val >= 0.5);
            dithered(r, c) = new_val;

            % Distribute quantisation error to neighbouring pixels
            % Floyd-Steinberg kernel:
            %           * 7/16
            %   3/16  5/16  1/16
            err = old_val - new_val;
            if c + 1 <= cols
                dithered(r,   c+1) = dithered(r,   c+1) + err * 7/16;
            end
            if r + 1 <= rows
                if c - 1 >= 1
                    dithered(r+1, c-1) = dithered(r+1, c-1) + err * 3/16;
                end
                dithered(r+1, c  ) = dithered(r+1, c  ) + err * 5/16;
                if c + 1 <= cols
                    dithered(r+1, c+1) = dithered(r+1, c+1) + err * 1/16;
                end
            end
        end
    end

    dithered = min(max(dithered, 0), 1);

    
    %  STEP 5: Phosphor colour
    %  White pixels glow slightly warm, black areas are deep green-black
    
    fprintf('Applying phosphor colour...\n');

    % Foreground (white) pixel colour - warm off-white with slight green
    fg_R = 0.88;  fg_G = 0.92;  fg_B = 0.82;

    % Background (black) pixel colour - deep phosphor black-green
    bg_R = 0.02;  bg_G = 0.04;  bg_B = 0.02;

    R = dithered * fg_R + (1 - dithered) * bg_R;
    G = dithered * fg_G + (1 - dithered) * bg_G;
    B = dithered * fg_B + (1 - dithered) * bg_B;

    img = cat(3, R, G, B);

    
    %  STEP 6: Scan lines
    %  Subtler than a 1950s TV but still present
    
    fprintf('Adding scan lines...\n');

    scanline_depth = 0.25 * strength;
    scanline_mask  = ones(rows, cols);
    scanline_mask(2:2:end, :) = 1 - scanline_depth;

    for ch = 1:3
        img(:,:,ch) = img(:,:,ch) .* scanline_mask;
    end

    
    %  STEP 7: Subtle pixel grid
    fprintf('Adding pixel grid...\n');

    pixel_grid_strength = 0.12 * strength;
    grid_mask = ones(rows, cols);

    % Every 2nd column gets a faint dark edge (vertical pixel boundary)
    grid_mask(:, 2:2:end) = 1 - pixel_grid_strength;

    for ch = 1:3
        img(:,:,ch) = img(:,:,ch) .* grid_mask;
    end

    
    %  STEP 8: Phosphor glow / bloom
    %  Bright pixels bleed slightly into neighbours on a CRT
    
    fprintf('Adding phosphor bloom...\n');

    glow_sigma = 0.8 * strength;
    w_glow     = fspecial('Gaussian', [5 5], glow_sigma);

    for ch = 1:3
        channel         = img(:,:,ch);
        channel_blur    = imfilter(channel, w_glow, 'replicate');
        highlight_mask  = max(channel - 0.5, 0) * 2;
        img(:,:,ch)     = min(channel + channel_blur .* highlight_mask * 0.2, 1);
    end

    
    %  STEP 9: Barrel distortion
    %  MThey had a gently curved CRT screen
    %  Less extreme than a 1960s TV but still noticeable
    
    fprintf('Applying screen curvature...\n');

    [X, Y] = meshgrid(linspace(-1, 1, cols), linspace(-1, 1, rows));
    barrel = 0.07 * strength;
    R2     = X.^2 + Y.^2;
    X_dist = X .* (1 + barrel * R2);
    Y_dist = Y .* (1 + barrel * R2);
    X_px   = (X_dist + 1) / 2 * (cols - 1) + 1;
    Y_px   = (Y_dist + 1) / 2 * (rows - 1) + 1;

    for ch = 1:3
        img(:,:,ch) = interp2(img(:,:,ch), X_px, Y_px, 'linear', 0);
    end

    
    %  STEP 10: Static noise
    %  Faint random pixel flicker - less than a 1960s TV, but present
    
    fprintf('Adding static...\n');

    noise_amount = 0.04 * strength;
    noise        = randn(rows, cols) * noise_amount;

    for ch = 1:3
        img(:,:,ch) = min(max(img(:,:,ch) + noise, 0), 1);
    end

    
    %  STEP 11: Vignette
    %  tv screen corners were dimmer due to CRT beam angle falloff
    
    fprintf('Adding vignette...\n');

    [Xv, Yv] = meshgrid(linspace(-1, 1, cols), linspace(-1, 1, rows));
    vignette  = 1 - strength * 0.5 * (Xv.^2 + Yv.^2).^0.9;
    vignette  = max(vignette, 0.2);

    for ch = 1:3
        img(:,:,ch) = img(:,:,ch) .* vignette;
    end

    
    %  STEP 12: Screen bezel mask

    
    fprintf('Applying bezel mask...\n');

    margin = 0.04;
    [Xm, Ym] = meshgrid(linspace(-1, 1, cols), linspace(-1, 1, rows));
    screen_mask = double((abs(Xm) < (1 - margin)) & (abs(Ym) < (1 - margin)));
    w_mask      = fspecial('Gaussian', [9 9], 2);
    screen_mask = imfilter(screen_mask, w_mask, 'replicate');

    for ch = 1:3
        img(:,:,ch) = img(:,:,ch) .* screen_mask;
    end

    final = uint8(img * 255);

    
    %  STEP 13: Display & Save
    
    fprintf('Displaying results...\n');

    figure('Name', 'TV Screen Effect', 'NumberTitle', 'off');
    imshow(final)
    imwrite(final, output_path);
    fprintf('Done! Result saved to: %s\n', output_path);

end
