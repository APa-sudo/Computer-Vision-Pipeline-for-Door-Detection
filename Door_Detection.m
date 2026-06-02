%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                         %
% Matlab Lab Testat Winter Term- Door Detection Project          %
%                                                                         %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clearvars
close all
clc

%%%% Loading the door photo %%%%%
% Switching to the first test image
raw_picture = imread('./01 - R2441 - i.JPG');
[rows, cols, colors] = size(raw_picture);
figure(1), imshow(raw_picture, 'Border', 'tight');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Task 1: Clean up the image - Fix contrast and blur out noise            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
disp('Running Task 1...');

% 1. Turn the color photo into a simple grayscale image
gray_view = rgb2gray(raw_picture);

% 2. Fix the lighting/contrast
% Stretching the brightness so it uses the whole range from 0 to 1.
high_con_img = imadjust(gray_view);

% 3. Smoothing it out with a 5x5 Binomial filter
% I'm using Pascal's triangle (row 4) for the weights: [1 4 6 4 1]
% Dividing by 16 so the image brightness stays the same.
smooth_weights = [1 4 6 4 1] / 16;

% Doing the blur in two steps (X then Y) to save processing time
temp_filtered = imfilter(high_con_img, smooth_weights, 'replicate');
clean_img = imfilter(temp_filtered, smooth_weights', 'replicate');
 

%%%% If you have no result load the given one %%%%

% load('Solutions_Task_1.mat')

figure(1), imshow(clean_img, 'Border', 'tight');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Task 2: Finding the edges (Feature Extraction)                          %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
disp('Running Task 2...');

% 1. Setting up the math for the edge filters
% Using Scharr values to find where colors change suddenly
diff_kernel = [-1 0 1];       
blur_kernel = [3 10 3];     
scaling = 1/32;     

img_as_dbl = double(clean_img);

% 2. Calculating the Gradients
% Finding vertical edges (changes in X)
x_change_tmp = imfilter(img_as_dbl, diff_kernel, 'replicate');
x_grad = imfilter(x_change_tmp, blur_kernel', 'replicate') * scaling;

% Finding horizontal edges (changes in Y)
y_change_tmp = imfilter(img_as_dbl, blur_kernel, 'replicate');
y_grad = imfilter(y_change_tmp, diff_kernel', 'replicate') * scaling;

% 3. Figure out how strong each edge is
total_edge_power = sqrt(x_grad.^2 + y_grad.^2);

% 4. Decide which edges are "real" and which are just noise
% Setting the cutoff based on the average brightness of the edges
avg_power = mean(total_edge_power(:));
limit = 2.5 * avg_power; 

% 5. Cleaning up the binary masks
% Part A: Split edges into "Light to Dark" and "Dark to Light"
neg_x_raw = x_grad < -limit; 
pos_x_raw = x_grad > limit;  
neg_y_raw = y_grad < -limit;
pos_y_raw = y_grad > limit;

% Part B: Delete tiny dots (noise) smaller than 5 pixels
neg_x_clean = bwareaopen(neg_x_raw, 5);
pos_x_clean = bwareaopen(pos_x_raw, 5);
neg_y_clean = bwareaopen(neg_y_raw, 5);
pos_y_clean = bwareaopen(pos_y_raw, 5);

% Part C: Make the lines a bit thicker so they are easier to see
box = strel('square', 3); 
final_neg_x = imdilate(neg_x_clean, box);
final_pos_x = imdilate(pos_x_clean, box);
final_neg_y = imdilate(neg_y_clean, box);
final_pos_y = imdilate(pos_y_clean, box);

% Mapping these to the variables used for the plots
img_sobel_x = x_grad;
img_edge_strength_x = total_edge_power; 
img_neg_edge_x = final_neg_x;
img_pos_edge_x = final_pos_x;
img_neg_edge_y = final_neg_y;
img_pos_edge_y = final_pos_y;

%%%% If you have no result load the given one %%%%

% load('Solutions_Task_2.mat')

%%%% Show the gradient and edge results %%%%
figure(2),imagesc(img_sobel_x); colorbar; colormap hsv; axis off;
figure(3),imagesc(log(1+img_edge_strength_x)); colorbar; axis off;
figure(4),imagesc(img_neg_edge_x); colormap gray; axis off;
figure(5),imagesc(img_pos_edge_x); colormap gray; axis off;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Task 3: Isolate the actual door gap lines                               %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
disp('Running Task 3...');

% 1. Find where edges overlap (symmetry)
% For vertical, we want both sides of the gap (AND). For horizontal, either works (OR).
v_overlap = final_neg_x & final_pos_x;
h_overlap = final_neg_y | final_pos_y;

% 2. Get rid of the "junk"
% Removing blobs smaller than 10 pixels
v_filtered = bwareaopen(v_overlap, 10);
h_filtered = bwareaopen(h_overlap, 10);

% 3. Fill in the holes
% If a line is broken (like by a door hinge), this bridges gaps up to 30 pixels
v_closed = imclose(v_filtered, strel('rectangle', [30, 2])); 
h_closed = imclose(h_filtered, strel('rectangle', [2, 30]));

% 4. Final fattening of the lines for the Hough step
v_final = imdilate(v_closed, strel('square', 3));
h_final = imdilate(h_closed, strel('square', 3));

% Setting up variables for the display loop
img_sym_x = double(v_overlap); 
candidates_x = v_final;
candidates_y = h_final;

%%%% If you have no result load the given one %%%%

% load('Solutions_Task_3.mat')

figure(8),imagesc(max(max(img_sym_x))-abs(img_sym_x)); colormap gray; axis off;
figure(9),imagesc(1-candidates_x); colormap gray; axis off;
figure(10),imagesc(1-candidates_y); colormap gray; axis off;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Task 4: Use Hough Transform to find the best lines                      %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
disp('Running Task 4...');

% --- 1. Looking for Vertical Lines ---
[Hv, Tv, Rv] = hough(candidates_x, 'Theta', -20:0.5:20);
rho_gap = floor(size(Hv, 1) / 20); 
% Find the 4 strongest peaks in the Hough data
peaks_v = houghpeaks(Hv, 4, 'Threshold', 0.05*max(Hv(:)), 'NHoodSize', [rho_gap 5]);
v_list = houghlines(candidates_x, Tv, Rv, peaks_v, 'FillGap', 300, 'MinLength', 60);

% If we found enough lines, pick the ones furthest to the left and right
if length(v_list) >= 2
    avg_x = arrayfun(@(l) (l.point1(1) + l.point2(1))/2, v_list);
    [~, sorted_idx] = sort(avg_x);
    chosen_v_lines = v_list(sorted_idx([1, end])); 
else
    chosen_v_lines = v_list;
end

% --- 2. Looking for Horizontal Lines (Top and Bottom) ---
% Split the image roughly at 60% height to look for the top frame and floor separately
split_mark = floor(rows * 0.6); 

% Top search
top_mask = candidates_y; top_mask(split_mark:end, :) = 0; 
[Ht, Tt, Rt] = hough(top_mask, 'Theta', [-89:-70, 70:89]);
if max(Ht(:)) > 0
    p_top = houghpeaks(Ht, 1, 'Threshold', 0.1*max(Ht(:)));
    line_top = houghlines(top_mask, Tt, Rt, p_top, 'FillGap', 150, 'MinLength', 50);
else
    line_top = [];
end

% Bottom search
bot_mask = candidates_y; bot_mask(1:split_mark, :) = 0; 
[Hb, Tb, Rb] = hough(bot_mask, 'Theta', [-89:-70, 70:89]);
if max(Hb(:)) > 0
    p_bot = houghpeaks(Hb, 1, 'Threshold', 0.05*max(Hb(:))); 
    line_bot = houghlines(bot_mask, Tb, Rb, p_bot, 'FillGap', 250, 'MinLength', 30);
else
    line_bot = [];
end

chosen_h_lines = [line_top, line_bot];

% Organizing lines into matrices for the plotting logic provided
l_x = zeros(3, 2);
for i = 1:min(2, length(chosen_v_lines))
    l_x(:, i) = [cosd(chosen_v_lines(i).theta); sind(chosen_v_lines(i).theta); -chosen_v_lines(i).rho];
end

l_y = zeros(3, 2);
for i = 1:min(2, length(chosen_h_lines))
    l_y(:, i) = [cosd(chosen_h_lines(i).theta); sind(chosen_h_lines(i).theta); -chosen_h_lines(i).rho];
end

%%%% If you have no result load the given one %%%%

% load('Solutions_Task_4.mat')

figure(11), imshow(clean_img); hold on;
for k=1:2
    if l_x(1,k) ~= 0 || l_x(2,k) ~= 0
        plot([round(-(l_x(2,k)+l_x(3,k))/l_x(1,k)); round(-(rows*l_x(2,k)+l_x(3,k))/l_x(1,k));], [1,rows], 'g');
    end
    if l_y(2,k) ~= 0 || l_y(1,k) ~= 0
        plot([1,cols], [round(-(l_y(1,k)+l_y(3,k))/l_y(2,k)); round(-(cols*l_y(1,k)+l_y(3,k))/l_y(2,k));], 'g');
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Task 5: Find where the lines cross (The Corners)                        %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
disp('Running Task 5...');

% 1. Identify which line is which
x_centers = arrayfun(@(l) (l.point1(1) + l.point2(1))/2, chosen_v_lines);
[~, x_sort] = sort(x_centers);
left_side = chosen_v_lines(x_sort(1));
right_side = chosen_v_lines(x_sort(end));

y_centers = arrayfun(@(l) (l.point1(2) + l.point2(2))/2, chosen_h_lines);
[~, y_sort] = sort(y_centers);
top_side = chosen_h_lines(y_sort(1));
bottom_side = chosen_h_lines(y_sort(end));

% 2. Calculate the intersection points (x,y)
% Using basic linear algebra to find where the lines meet
find_cross = @(v, h) [cosd(v.theta) sind(v.theta); cosd(h.theta) sind(h.theta)] \ [v.rho; h.rho];

cor_lu = find_cross(left_side, top_side);   % Top Left
cor_ru = find_cross(right_side, top_side);  % Top Right
cor_lb = find_cross(left_side, bottom_side);   % Bottom Left
cor_rb = find_cross(right_side, bottom_side);  % Bottom Right

% 3. Format vectors for the final plot
l_x_left  = [cosd(left_side.theta);  sind(left_side.theta);  -left_side.rho];
l_x_right = [cosd(right_side.theta); sind(right_side.theta); -right_side.rho];
l_y_up    = [cosd(top_side.theta);   sind(top_side.theta);   -top_side.rho];
l_y_down  = [cosd(bottom_side.theta);   sind(bottom_side.theta);   -bottom_side.rho];

%%%% If you have no result load the given one %%%%

% load('Solutions_Task_5.mat')

figure(12), imshow(clean_img); hold on;
% Draw the 4 main lines in red and green
plot([round(-(l_x_left(2)+l_x_left(3))/l_x_left(1)); round(-(rows*l_x_left(2)+l_x_left(3))/l_x_left(1));], [1,rows], 'r');
plot([round(-(l_x_right(2)+l_x_right(3))/l_x_right(1)); round(-(rows*l_x_right(2)+l_x_right(3))/l_x_right(1));], [1,rows], 'g');
plot([1,cols], [round(-(l_y_up(1)+l_y_up(3))/l_y_up(2)); round(-(cols*l_y_up(1)+l_y_up(3))/l_y_up(2));], 'r');
plot([1,cols], [round(-(l_y_down(1)+l_y_down(3))/l_y_down(2)); round(-(cols*l_y_down(1)+l_y_down(3))/l_y_down(2));], 'g');

% Mark the corners with colored dots
plot(cor_lb(1), cor_lb(2), 'ro', 'MarkerFaceColor', 'r');
plot(cor_lu(1), cor_lu(2), 'go', 'MarkerFaceColor', 'g');
plot(cor_ru(1), cor_ru(2), 'bo', 'MarkerFaceColor', 'b');
plot(cor_rb(1), cor_rb(2), 'ko', 'MarkerFaceColor', 'k');

% Print the final coordinates
fprintf('LU Corner: (%.2f, %.2f)\n', cor_lu);
fprintf('RU Corner: (%.2f, %.2f)\n', cor_ru);
fprintf('LB Corner: (%.2f, %.2f)\n', cor_lb);
fprintf('RB Corner: (%.2f, %.2f)\n', cor_rb);
