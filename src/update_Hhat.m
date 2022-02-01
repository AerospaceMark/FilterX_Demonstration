function Hhat = update_Hhat(Hhat,Phat,x,e,u,alpha)

    y_estimate =  Hhat' * u;

    d_estimate = Phat' * x;
    epsilon = e - (y_estimate + d_estimate);
    Hhat = Hhat + alpha*epsilon(1).*u;

end