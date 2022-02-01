function r = get_r(r,x,Hhat)

    r = circshift(r,1);
    r(1) = Hhat' * x;

end