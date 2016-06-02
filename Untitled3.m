clear;close all;clc;
figure;
t = 0:pi/50:10*pi;
st = sin(t);
ct = cos(t);
h=gca;
plot3(st,ct,t);