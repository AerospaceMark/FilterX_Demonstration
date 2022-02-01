function x = addFeedback(x,n,y,F)
    
    x = circshift(x,1);
    x(1) = n(1) + F' * circshift(y,1); % circshift(y) was sort of a guess
                                       % but it turned out great.

end