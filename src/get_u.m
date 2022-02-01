function u = get_u(u,x,W)

    u = circshift(u,1);
    u(1) = W' * x;
    
end