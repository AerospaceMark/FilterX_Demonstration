function W = update_W(W,e,r,mu)

    W = W - mu*e(1).*r;

end