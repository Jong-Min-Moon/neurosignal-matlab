alpha = randn(60,1)*.4+pi/2;
figure

circ_plot(alpha,'hist',[],20,true,false,'linewidth',2,'color','red')
title('hist plot style')
