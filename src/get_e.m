function e = get_e(e,y,d,AddedNoiseToError)

    e = circshift(e,1);
    e(1) = d(1) + y(1);
    
    e(1) = e(1) + randn(1) * AddedNoiseToError;

end