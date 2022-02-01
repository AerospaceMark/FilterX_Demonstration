function y = get_y(y,u,H)

    y = circshift(y,1); 
    y(1) = H' * u;

end