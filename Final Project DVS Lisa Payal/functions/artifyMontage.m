function artifyMontage(input_path, output_path)

    if nargin < 1
        error('artifyMontage requires at least one argument: input image path.');
    end
    if nargin < 2 || isempty(output_path)
        output_path = 'artify_montage.png';
    end

    tmp_davinci  = 'tmp_davinci.png';
    tmp_halftone = 'tmp_halftone.png';
    tmp_tv       = 'tmp_tv.png';
    tmp_pixel    = 'tmp_pixel.png';

    daVinciNotebook(input_path, tmp_davinci);
    close all;
    halftoneImage(input_path, tmp_halftone);
    close all;
    tvSixties(input_path, tmp_tv);
    close all;
    pixellateImage(input_path, tmp_pixel);
    close all;

    original = imread(input_path);
    img_dv   = imread(tmp_davinci);
    img_ht   = imread(tmp_halftone);
    img_tv   = imread(tmp_tv);
    img_px   = imread(tmp_pixel);

    if size(original, 3) == 1
        original = cat(3, original, original, original);
    end

    target_size = [size(original, 1), size(original, 2)];
    img_dv  = imresize(img_dv,  target_size);
    img_ht  = imresize(img_ht,  target_size);
    img_tv  = imresize(img_tv,  target_size);
    img_px  = imresize(img_px,  target_size);

    img_dv   = ensureRGB(img_dv);
    img_ht   = ensureRGB(img_ht);
    img_tv   = ensureRGB(img_tv);
    img_px   = ensureRGB(img_px);
    original = ensureRGB(original);

    gap    = 8;
    bg     = [20 20 20];
    [h, w, ~] = size(original);

    canvas_w = w * 5 + gap * 4;
    canvas   = uint8(repmat(reshape(bg, 1, 1, 3), h, canvas_w));

    canvas(:, 1:w,                       :) = original;
    canvas(:, w+gap+1:w*2+gap,           :) = img_dv;
    canvas(:, w*2+gap*2+1:w*3+gap*2,     :) = img_ht;
    canvas(:, w*3+gap*3+1:w*4+gap*3,     :) = img_tv;
    canvas(:, w*4+gap*4+1:end,           :) = img_px;

    figure('Name', 'Artify', 'NumberTitle', 'off', 'Color', bg / 255);
    imshow(canvas);

    imwrite(canvas, output_path);

    delete(tmp_davinci);
    delete(tmp_halftone);
    delete(tmp_tv);
    delete(tmp_pixel);

    [d, n, e] = fileparts(tmp_pixel);
    tmp_pixel_nat = fullfile(d, [n '_natural' e]);
    if isfile(tmp_pixel_nat)
        delete(tmp_pixel_nat);
    end

end

function img = ensureRGB(img)
    if size(img, 3) == 1
        img = cat(3, img, img, img);
    end
    if ~isa(img, 'uint8')
        img = uint8(img);
    end
end
