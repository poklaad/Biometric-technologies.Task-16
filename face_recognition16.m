ImagePath = fullfile('E:\Учеба\Биометрические_технологии\16\Images', 'img_849.jpg');
I_rgb = imread(ImagePath);
[M, N, ~] = size(I_rgb);

% Преобразование в цветовое пространство HSV
I_hsv = rgb2hsv(I_rgb);
H = I_hsv(:,:,1);
S = I_hsv(:,:,2);
V = I_hsv(:,:,3);

% Преобразование в цветовое пространство YCbCr
I_ycbcr = rgb2ycbcr(I_rgb);
Y  = I_ycbcr(:,:,1);
Cb = I_ycbcr(:,:,2);
Cr = I_ycbcr(:,:,3);

% Преобразование в цветовое пространство I1I2I3
I_d = im2double(I_rgb);
R = I_d(:,:,1);
G = I_d(:,:,2);
B = I_d(:,:,3);
I1 = (R + G + B) / 3;
I2 = R - B;
I3 = (2*G - R - B)/2;

% Создание масок для каждого цветового пространства
% Маска для HSV:
MASKA_HSV = zeros(M,N);
cond_H = ((H >= 0 & H <= 0.15) | (H >= 0.9 & H <= 1));
cond_S = (S >= 0.2 & S <= 0.8);
cond_V = (V >= 0.2);
MASKA_HSV(cond_H & cond_S & cond_V) = 1;

% Маска для YCbCr:
MASKA_YCbCr = zeros(M,N);
cond_Cr = (Cr > 135 & Cr < 178);
cond_CbCr = ((Cb + 0.6*Cr) > 175 & (Cb + 0.6*Cr) < 225);
MASKA_YCbCr(cond_Cr & cond_CbCr) = 1;

% Маска для I1I2I3:
MASKA_I123 = zeros(M,N);
grayImg = rgb2gray(I_rgb);
meanBrightness = mean2(grayImg);
cond_I2 = (I2 > 0.1 & I2 < 0.8);
cond_I3 = (I3 > -0.2 & I3 < 0.1);
MASKA_I123(cond_I2 & cond_I3) = 1;

% Выбор маски для дальнейшей обработки
prompt = sprintf("Choose color space\nHSV: 1\nYCbCr: 2\nI1I2I3r: 3\n");
x = input(prompt);
switch(x)
    case 1
        MASK = MASKA_HSV;
    case 2
        MASK = MASKA_YCbCr;
    case 3
        MASK = MASKA_I123;
end

% Применение медианного фильтра для удаления шума
MASK_filt = medfilt2(MASK, [5 5]);

% Низкочастотная фильтрация для выделения наибольшего по площади пятна
h = fspecial('gaussian', [15 15], 5);
filtered = imfilter(double(MASK_filt), h, 'same');

% Определим максимум
[max_val, linear_ind] = max(filtered(:));

% Уровень порога
threshold_level = 0.75 * max_val;

% Формируем новую маску, отсекая всё что ниже threshold_level
MASK_cut = filtered >= threshold_level;

% MASK_cut определяет лицо.
% Выделяем только самое большое пятно
CC = bwconncomp(MASK_cut); % Находим связные компоненты
numPixels = cellfun(@numel, CC.PixelIdxList); % Считаем размеры пятен
[~, idx] = max(numPixels); % Находим индекс самого большого пятна
MASK_cut = zeros(size(MASK_cut)); % Очищаем маску
MASK_cut(CC.PixelIdxList{idx}) = 1; % Сохраняем только самое большое пятно

% Отобразим результат на исходном изображении
% Границы маски на изображении
BW_outline = bwperim(MASK_cut);
overlay_img = I_rgb;
overlay_img(:,:,1) = uint8(double(overlay_img(:,:,1)) + 255 * BW_outline); % Красный канал
overlay_img(:,:,2) = uint8(double(overlay_img(:,:,2)) .* ~BW_outline);
overlay_img(:,:,3) = uint8(double(overlay_img(:,:,3)) .* ~BW_outline);

% Отобразим результаты
figure; imshow(I_rgb); title('Исходное изображение');
figure; imshow(MASK,[]); title('Изначальная бинарная маска');
figure; imshow(MASK_filt,[]); title('После медианного фильтра');
figure; imshow(filtered,[]); title('После низкочастотной фильтрации');
figure; imshow(MASK_cut,[]); title('Маска с выделенной частью лица');
figure; imshow(overlay_img); title('Исходное изображение с наложением границ маски');
