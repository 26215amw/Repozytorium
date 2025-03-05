% Analiza trajektorii nurka wideo w Matlabie
% Autor: Paweł Piskur
% Data ostatniej aktualizacji: 2025-02-27
% 
% Program analizuje trajektorię ruchu nurka na podstawie nagrania wideo.
% Celem jest wyznaczenie trajektorii tułowia (lub głowy) oraz płetw nurka,
% a następnie obliczenie prędkości w m/s przy założeniu, że wzrost nurka wynosi 1.75 m.
% 
% Program wykorzystuje:
% - Import i przetwarzanie plików wideo MP4
% - Analizę macierzy (każda klatka to macierz RGB)
% - Pętle i warunki logiczne do analizy obrazu
% - Wykorzystanie regionprops do lokalizacji obiektów
% - Przeliczenie pikseli na metry
% - Wizualizację wyników
% - Odtworzenie dźwięku po zakończeniu analizy

clc; clear; close all;

% Import pliku wideo
filename = 'MAriusz_razem_jetfin.mp4'; 
data = VideoReader(filename);

% Wczytanie kilku wybranych klatek filmu
totalFrames = data.NumFrames;
frame_1 = read(data, 1);
frame_15 = read(data, 15);
frame_inf = read(data, totalFrames);

% Sprawdzenie wymiarów macierzy
wymiar_macierzy_15 = size(frame_15);
disp(['Wymiar macierzy klatka_15: ', num2str(wymiar_macierzy_15)]);

% Wizualizacja klatek
figure; imshow(frame_1); title('Klatka 1');
figure; imshow(frame_15); title('Klatka 15');
figure; imshow(frame_inf); title('Ostatnia klatka');
% imtool(frame_15)
% Wyodrębnienie poszczególnych macierzy RGB
R = frame_inf(:,:,1);
G = frame_inf(:,:,2);
B = frame_inf(:,:,3);

% narzędzie imtool
%%
% Filtracja obrazu - detekcja płetw
G_copy = G;
fin = G_copy < 60;
figure; imshow(fin); title('Maska płetw');
%%
% Modyfikacja obrazu
G_copy_2 = G;
G_copy_2(G_copy_2 < 50) = 255;
G_copy_2(G_copy_2 > 60) = 255;
figure; imshow(G_copy_2); title('Przetworzony kanał G');
%%
% Analiza trajektorii nurka
[nr_row, nr_col] = size(fin);
F = true(50);
[row_F, col_F] = size(F);

CalcFrames = totalFrames;
x_head = zeros(1, CalcFrames);
y_head = zeros(1, CalcFrames);
x_corp = zeros(1, CalcFrames);
y_corp = zeros(1, CalcFrames);
x_fin = zeros(1, CalcFrames);
y_fin = zeros(1, CalcFrames);

for kk = 1:10:CalcFrames
    frame_in = read(data, kk);
    frame = imrotate(frame_in, 180); % Obracamy obraz
    G = frame(:,:,2);
    fin = G < 60;
    
    %Pletwy_F_1 = zeros(nr_row-row_F-1, nr_col-col_F-1);
    Pletwy_F_2 = false(nr_row-row_F-1, nr_col-col_F-1);
    
    for i = 1:nr_row-row_F-1
        for j = 1:nr_col-col_F-1
            if fin(i:i+col_F-1, j:j+col_F-1) ~= F
                %Pletwy_F_1(i, j) = 0;
                Pletwy_F_2(i, j) = false;
            else
                %Pletwy_F_1(i, j) = 255;
                Pletwy_F_2(i, j) = true;
            end
        end
    end
    
    wsp = regionprops(Pletwy_F_2, 'Centroid');
    wsp_2 = cat(1, wsp.Centroid);
    wsp_2 = sortrows(wsp_2, 2, 'descend'); % Sortowanie po osi Y
    
    if size(wsp_2, 1) >= 1
        x_head(kk) = wsp_2(1, 1);
        y_head(kk) = wsp_2(1, 2);
    end
    if size(wsp_2, 1) >= 2
        x_corp(kk) = wsp_2(2, 1);
        y_corp(kk) = wsp_2(2, 2);
    end
    if size(wsp_2, 1) >= 3
        x_fin(kk) = wsp_2(3, 1);
        y_fin(kk) = wsp_2(3, 2);
    end
end

% Wykres trajektorii w pikselach
figure;
plot(x_corp, y_corp, 'ro'); hold on;
plot(x_fin, y_fin, 'bo');
plot(x_head, y_head, 'go');
title('Odległość w pikselach');
xlabel('Odległość ');
ylabel('Głębokość ');
legend('Płetwy', 'Ciało', 'Głowa');
grid on;
hold off;

% Przeliczenie na metry
pix_to_m = 1.75 / 750;
m_pletwy_x = x_fin * pix_to_m;
m_pletwy_y = y_fin * pix_to_m;
m_cialo_x = x_corp * pix_to_m;
m_cialo_y = y_corp * pix_to_m;
m_glowa_x = x_head * pix_to_m;
m_glowa_y = y_head * pix_to_m;

% Wykres trajektorii w metrach
figure;
plot(m_pletwy_x, m_pletwy_y, 'ro'); hold on;
plot(m_cialo_x, m_cialo_y, 'bo');
plot(m_glowa_x, m_glowa_y, 'go');
title('Odległość w metrach');
xlabel('x [m]');
ylabel('y [m]');
legend('Płetwy', 'Ciało', 'Głowa');
grid on;
hold off;

% Odtworzenie dźwięku po zakończeniu
load handel
sound(y, Fs)

disp('Analiza zakończona.');