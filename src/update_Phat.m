function Phat = update_Phat(Phat,Hhat,x,e,u,alpha)

    y_estimate =  Hhat' * u;

    d_estimate = Phat' * x;
    epsilon = e - (y_estimate + d_estimate);
    Phat = Phat + alpha*epsilon(1).*x;

end