function image_filter_app
    % Создаем фигуру для интерфейса
    fig = figure('Name', 'Фильтрация изображения', 'Position', [100, 100, 800, 600]);

    % Кнопка для загрузки изображения
    uicontrol('Style', 'pushbutton', 'String', 'Загрузить изображение', ...
              'Position', [50, 550, 150, 40], 'Callback', @load_image);

    % Меню выбора фильтра
    filterMenu = uicontrol('Style', 'popupmenu', 'String', {'Среднее арифметическое', 'Среднее геометрическое', ...
                   'Среднее гармоническое', 'Среднее контрагармоническое', 'Медианный фильтр', ...
                   'Максимально-минимальный фильтр', 'Фильтр Лапласа', 'Фильтр средней точки', 'Усеченное среднее'}, ...
                   'Position', [250, 550, 180, 40]);

    % Кнопка для применения фильтрации
    uicontrol('Style', 'pushbutton', 'String', 'Применить фильтр', ...
              'Position', [450, 550, 150, 40], 'Callback', @apply_filter);

    % Axes для отображения исходного и обработанного изображения
    ax1 = axes('Units', 'pixels', 'Position', [50, 50, 350, 450]);
    ax2 = axes('Units', 'pixels', 'Position', [400, 50, 350, 450]);

    % Исходное и обработанное изображение
    originalImage = [];
    filteredImage = [];

    % Загрузка изображения
    function load_image(~, ~)
        [filename, pathname] = uigetfile({'*.jpg;*.png;*.bmp', 'Image Files (*.jpg, *.png, *.bmp)'}, ...
                                        'Выберите изображение');
        if filename ~= 0
            filepath = fullfile(pathname, filename);
            originalImage = imread(filepath);
            imshow(originalImage, 'Parent', ax1);
            title(ax1, 'Исходное изображение');
            cla(ax2);
            title(ax2, '');
        end
    end

    % Применение фильтра
    function apply_filter(~, ~)
        if isempty(originalImage)
            warndlg('Сначала загрузите изображение', 'Ошибка');
            return;
        end

        filterIndex = get(filterMenu, 'Value');
        try
            filteredImage = apply_selected_filter(originalImage, filterIndex);
            imshow(filteredImage, 'Parent', ax2);
            title(ax2, 'Отфильтрованное изображение');
        catch ME
            errordlg(['Ошибка при применении фильтра: ' ME.message], 'Ошибка фильтрации');
        end
    end

    % Функция выбора фильтра
    function image = apply_selected_filter(image, index)
        img = double(image); % Преобразуем изображение в double для обработки
        [rows, cols, channels] = size(img);
        filteredImg = zeros(size(img));
        
        switch index
            case 1 % Среднее арифметическое
                h = fspecial('average', [5 5]);
                for k = 1:channels
                    filteredImg(:,:,k) = imfilter(img(:,:,k), h, 'replicate');
                end
                
            case 2 % Среднее геометрическое
                for k = 1:channels
                    filteredImg(:,:,k) = exp(imfilter(log(img(:,:,k) + 1), fspecial('average', [5 5]), 'replicate')) - 1;
                end
                
            case 3 % Среднее гармоническое
            h = fspecial('average', [5 5]);
            for k = 1:channels
                img_channel = img(:,:,k) + eps; % Добавляем eps для избежания деления на ноль
                harmonic = imfilter(1 ./ img_channel, h, 'replicate');
                filteredImg(:,:,k) = rows * cols ./ harmonic;
                % Масштабируем результат
                filteredImg(:,:,k) = 255 * (filteredImg(:,:,k) / max(filteredImg(:,:,k), [], 'all'));
            end
            case 4 % Среднее контрагармоническое
                Q = 1.5; % Коэффициент Q
                for k = 1:channels
                    num = imfilter(img(:,:,k) .^ (Q + 1), fspecial('average', [5 5]), 'replicate');
                    den = imfilter(img(:,:,k) .^ Q, fspecial('average', [5 5]), 'replicate');
                    filteredImg(:,:,k) = num ./ den;
                end
                
            case 5 % Медианный фильтр
                for k = 1:channels
                    filteredImg(:,:,k) = medfilt2(img(:,:,k), [5 5]);
                end
                
            case 6 % Максимально-минимальный фильтр
                for k = 1:channels
                    maxF = ordfilt2(img(:,:,k), 25, true(5)); % Максимальное значение
                    minF = ordfilt2(img(:,:,k), 1, true(5));  % Минимальное значение
                    filteredImg(:,:,k) = maxF - minF;
                end
                
            case 7 % Фильтр Лапласа
                for k = 1:channels
                    filteredImg(:,:,k) = imfilter(img(:,:,k), fspecial('laplacian'), 'replicate');
                end
                
           case 8 % Фильтр средней точки с улучшенной обработкой краев
                kernelSize = 3;
                pad = floor(kernelSize / 2);
                paddedImage = padarray(img, [pad pad], 'symmetric');
                for c = 1:channels
                    for i = 1 + pad : rows + pad
                        for j = 1 + pad : cols + pad
                            window = paddedImage(i-pad:i+pad, j-pad:j+pad, c);
                            maxVal = max(window(:));
                            minVal = min(window(:));
                            filteredImg(i-pad, j-pad, c) = (maxVal + minVal) / 2;
                        end
                    end
                end
                
          case 9 % Усеченное среднее
            kernel_size = 5; % Размер ядра
            trim = 0.3; % Процент усечения
            pad = floor(kernel_size / 2);
            padded_img = padarray(img, [pad pad], 'symmetric');

            for c = 1:channels
                channel_filtered = zeros(rows, cols);
                for i = 1 + pad : rows + pad
                    for j = 1 + pad : cols + pad
                        window = padded_img(i-pad:i+pad, j-pad:j+pad, c);
                        sorted_window = sort(window(:));
                        trim_count = floor(numel(sorted_window) * trim);
                        trimmed_window = sorted_window(trim_count+1:end-trim_count);
                        channel_filtered(i-pad, j-pad) = mean(trimmed_window);
                    end
                end
                filteredImg(:, :, c) = channel_filtered;
            end
        end
        image = uint8(filteredImg);
    end
end
