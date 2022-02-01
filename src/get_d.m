function d = get_d(d,n,P)

    d = circshift(d,1);
    d(1) = P' * n;

end