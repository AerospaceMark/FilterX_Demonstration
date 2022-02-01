function [attenuation, times, SNR_extraNoise] = filterX(varargin)

    % Defining the inputs
    p = inputParser;
    p.addParameter('ControllerDelay',0); % tau
    p.addParameter('PlantDelay',0); % delta
    p.addParameter('NumCoefficients',20); % For W
    p.addParameter('SampleRate',1000); % Don't change
    p.addParameter('ControlParameter',0.01); % mu
    p.addParameter('Animate',false);
    p.addParameter('NoiseType','tone');
    p.addParameter('ToneFrequency',220);
    p.addParameter('ProduceFinalPlot',true);
    p.addParameter('RecordingTime',1);
    p.addParameter('Pcoeff',0.99);
    p.addParameter('Fcoeff',0.99);
    p.addParameter('Hcoeff',0.99);
    p.addParameter('ProduceAttenuationPlot',false)
    p.addParameter('AddedNoiseToError',0.0);
    p.addParameter('PassiveID_H',false);
    p.addParameter('PassiveID_P',false);
    p.addParameter('Alpha',0.001); % For updating Hhat
    p.addParameter('ProducePassiveIDPlot',false)
    
    % Parsing the inputs
    p.parse(varargin{:});
    tau             = p.Results.ControllerDelay;
    delta           = p.Results.PlantDelay;
    N               = p.Results.NumCoefficients;
    fs              = p.Results.SampleRate;
    mu              = p.Results.ControlParameter;
    Animate         = p.Results.Animate;
    NoiseType       = p.Results.NoiseType;
    ToneFrequency   = p.Results.ToneFrequency;
    ProduceFinalPlot= p.Results.ProduceFinalPlot;
    RecordingTime   = p.Results.RecordingTime;
    Pcoeff          = p.Results.Pcoeff;
    Fcoeff          = p.Results.Fcoeff;
    Hcoeff          = p.Results.Hcoeff;
    AttenuationPlot = p.Results.ProduceAttenuationPlot;
    AddedNoiseToError = p.Results.AddedNoiseToError;
    PassiveID_H     = p.Results.PassiveID_H;
    PassiveID_P     = p.Results.PassiveID_P;
    alpha           = p.Results.Alpha;
    PassiveIDPlot   = p.Results.ProducePassiveIDPlot;

    %----------------- Constants ----------------------------%
    n = zeros(N,1); % Buffer
    u = zeros(N,1); % Output after going through the filter
    y = zeros(N,1); % Final signal to use for ANC
    d = zeros(N,1); % Signal after propagating down system
    e = zeros(N,1); % Error signal
    r = zeros(N,1); % Reference signal
    x = zeros(N,1); % Noise after feedback
    
    %------------------ Transfer Functions -------------------%
    % Coefficients
    W = zeros(N,1);
    
    % System transfer function
    H = zeros(N,1);
    H(tau+1) = Hcoeff;
    
    % Transfer function between source & receiver
    P = zeros(N,1);
    P(delta+1) = Pcoeff;

    % Estimate of system transfer function
    if PassiveID_P
        Phat = zeros(N,1) + 0.01; % Must start as non-zero.
    else
        Phat = P;
    end
    
    % Feedback loop
    F = zeros(N,1);
    F(delta+1) = Fcoeff;
    
    % Estimate of system transfer function
    if PassiveID_H
        Hhat = zeros(N,1) + 0.01; % Must start as non-zero.
    else
        Hhat = H;
    end
    
    % For seeing the error history
    totalError = [];
    
    % Optimal Coefficient Weights
    Pfreq = freqz(P);
    Hfreq = freqz(H);
    Ffreq = freqz(F);
    Wopt = -Pfreq./(Hfreq .* (1 - Ffreq.*Pfreq));
    
    % Initializing total attenuation and times arrays
    attenuation = [];
    times = [];
    
    % For easily seeing the time series data
    total_d = [];
    total_y = [];

    % Defining the figure size if showing plot
    if Animate || ProduceFinalPlot
        % Defining the figure
        h = figure();
        h.Units = 'inches';
        h.Position = [10,1,6.5,9];
    end

    %---------------------- MAIN LOOP FOR THE ALGORITHM ------------------%
    for i = 1:fs*RecordingTime

        % update the incoming array n(t)
        switch lower(NoiseType)
            
            case 'tone'
                
                n = addToNoise(n,@sin,ToneFrequency*(2*pi) * i/fs);
                
            case 'noise'
                
                n = addToNoise(n,@randn,1);
                
        end

        % Pass n(t) through P to produce d(t)
        d = get_d(d,n,P);

        % Include feedback in n(t) to produce x(t)
        x = addFeedback(x,n,y,F);

        % Pass x(t) through Hhat to produce r(t)
        r = get_r(r,x,Hhat);

        % Send x(t) to the coefficients and produce u(t)
        u = get_u(u,x,W);

        % Pass u(t) through the transfer function H to produce y(t)
        y = get_y(y,u,H);

        % Add y(t) and d(t) to produce e(t)
        e = get_e(e,y,d,AddedNoiseToError);
        totalError = [totalError;e(1)];

        % Multiply e(t) and r(t) and use the result to update W
        W = update_W(W,e,r,mu);

        % If using online passive identification, update Hhat
        if PassiveID_P

            Phat = update_Phat(Phat,Hhat,x,e,u,alpha);

        end

        % If using online passive identification, update Hhat
        if PassiveID_H

            Hhat = update_Hhat(Hhat,Phat,x,e,u,alpha);

        end
        
        % Get the current attenuation
        if mod(i,fs/10)
            nsquared = rms(n)^2;
            esquared = rms(e)^2;
            
            attenuation = [attenuation;10*log10(nsquared/esquared)];
            times = [times;i/fs];
            
        end
        
        % Getting the total n(t) and y(t)
        total_d = [total_d;d(1)];
        total_y = [total_y;y(1)];

        %-------------- Create plots --------------%
        if Animate
            createPlots(fs,n,total_d,total_y,totalError,W,Wopt,Hhat,Phat,PassiveID_H,PassiveID_P)
        end
            
    end
    
    % If extra noise is added, calculate the SNR relative to n(t)
    extraNoise = randn(length(total_d),1) .* AddedNoiseToError;
    SNR_extraNoise = 20*log10(rms(total_d)/rms(extraNoise));
    
    if ProduceFinalPlot
 
        createPlots(fs,n,total_d,total_y,totalError,W,Wopt,Hhat,Phat,PassiveID_H,PassiveID_P)
        
        stitle = sgtitle(strcat("Convergence with n(t) = ",convertCharsToStrings(NoiseType),...
                        " and \mu = ",num2str(mu)));
        stitle.FontName = 'Arial';
        stitle.FontWeight = 'Bold';
        stitle.FontSize = 16;
        
        subplot(5,1,1)
        legend('Location','NorthEast')
        
        subplot(5,1,3)
        legend('Location','NorthEast')

        subplot(5,1,4)
        legend('Location','NorthEast')
        
        subplot(5,1,5)
        legend('Location','NorthEast')
    
    end
    
    % Attenuation vs Time Plot
    if AttenuationPlot
        
        figure()
        plot(times,attenuation)
        title('Attenuation Function')
        xlabel('Time (s)')
        ylabel('Attenuation (dB)')
        grid on
        
    end
    
    if PassiveIDPlot
        
        if PassiveID_H

            figure()
            subplot(2,1,1)
            [Hhat_frequency_domain,Hhat_freqs] = freqz(Hhat);
            [H_frequency_domain,H_freqs] = freqz(H);
            Hhat_freqs = Hhat_freqs ./ (2*pi) .* fs;
            H_freqs = H_freqs ./ (2*pi) .* fs;
            plot(Hhat_freqs,abs(Hhat_frequency_domain),'DisplayName','Calculated','LineWidth',2)
            hold on
            plot(H_freqs,abs(H_frequency_domain),'r--','LineWidth',2,'DisplayName','Ideal')
            hold off
            xlim([0,500])
            ylim([-0.01,1.1*max(abs(Hhat_frequency_domain))])
            title('Hhat Frequency Response (Magnitude)')
            xlabel('Frequency (Hz)')
            ylabel('Amplitude')
            grid on
            
            subplot(2,1,2)
            plot(Hhat_freqs,angle(Hhat_frequency_domain),'DisplayName','Calculated','LineWidth',2)
            xlim([10,500])
            hold on
            plot(H_freqs,angle(H_frequency_domain),'r--','LineWidth',2,'DisplayName','Ideal')
            hold off
            title('Hhat Frequency Response (Phase)')
            xlabel('Frequency (Hz)')
            ylabel('Phase')
            grid on

        end

        if PassiveID_P

            figure()
            subplot(2,1,1)
            [Phat_frequency_domain,Phat_freqs] = freqz(Phat);
            [P_frequency_domain,P_freqs] = freqz(P);
            Phat_freqs = Phat_freqs ./ (2*pi) .* fs;
            P_freqs = P_freqs ./ (2*pi) .* fs;
            plot(Phat_freqs,abs(Phat_frequency_domain),'DisplayName','Calculated','LineWidth',2)
            hold on
            plot(P_freqs,abs(P_frequency_domain),'r--','LineWidth',2,'DisplayName','Ideal')
            hold off
            xlim([0,500])
            ylim([-0.01,1.1*max(abs(Phat_frequency_domain))])
            title('Phat Frequency Response (Magnitude)')
            xlabel('Frequency (Hz)')
            ylabel('Amplitude')
            grid on
            
            subplot(2,1,2)
            plot(Phat_freqs,angle(Phat_frequency_domain),'DisplayName','Calculated','LineWidth',2)
            xlim([10,500])
            hold on
            plot(P_freqs,angle(P_frequency_domain),'r--','LineWidth',2,'DisplayName','Ideal')
            hold off
            title('Phat Frequency Response (Phase)')
            xlabel('Frequency (Hz)')
            ylabel('Phase')
            grid on

        end
        
    end
    
end

function createPlots(fs,n,total_d,total_y,totalError,W,Wopt,Hhat,Phat,PassiveID_H,PassiveID_P)

    dt = 1/fs;
    t = 0:dt:(length(n)*dt - dt);
    
    t_d = 0:dt:(length(total_d)*dt - dt);

    subplot(5,1,1)
    plot(t_d,total_d,'DisplayName','d(t)'); hold on
    plot(t_d,total_y,'DisplayName','y(t)'); hold off
    ylim([-3,3])
    xlim([length(total_d)/fs - 0.1,length(total_d)/fs])
    title('Waveforms')
    xlabel('Time (s)')
    ylabel('Pressure (Pa)')
    grid on

    subplot(5,1,2)
    t_error = 0:dt:(length(totalError)*dt - dt);
    plot(t_error,totalError,'DisplayName','error')
    title('Error')
    xlabel('Time (s)')
    ylabel ('Error')
    grid on

    subplot(5,1,3)
    plot(t(1:length(W)),W,'DisplayName','W Estimate'); hold on
    
    if PassiveID_H
    
        plot(t(1:length(W)),Hhat,'DisplayName','H Estimate')
        
    end

    if PassiveID_P
    
        plot(t(1:length(W)),Phat,'DisplayName','P Estimate','Color',[0,0.9,0])
        
    end

    hold off
    ylim([-1.1*max([max(abs(W)+0.001),max(abs(Hhat)+0.001),max(abs(Phat)+0.001)]),...
           1.1*max([max(abs(W)+0.001),max(abs(Hhat)+0.001),max(abs(Phat)+0.001)])])
    title('Filter Coefficients')
    xlabel('Filter Time Index')
    ylabel('Value')
    grid on

    subplot(5,1,4)
    [W_frequency_domain,W_freqs] = freqz(W);
    W_freqs = W_freqs ./ (2*pi) .* fs;
    plot(W_freqs,abs(W_frequency_domain),'DisplayName','Calculated','LineWidth',2)
    hold on
    plot(W_freqs,abs(Wopt),'r--','LineWidth',2,'DisplayName','Ideal')
    hold off
    xlim([0,500])
    ylim([-0.01,1.1*max(abs(W_frequency_domain))])
    title('Filter Frequency Response (Magnitude)')
    xlabel('Frequency (Hz)')
    ylabel('Amplitude')
    grid on

    subplot(5,1,5)
    plot(W_freqs,angle(W_frequency_domain),'DisplayName','Calculated','LineWidth',2)
    xlim([10,500])
    hold on
    plot(W_freqs,angle(Wopt),'r--','LineWidth',2,'DisplayName','Ideal')
    hold off
    title('Filter Frequency Response (Phase)')
    xlabel('Frequency (Hz)')
    ylabel('Phase')
    grid on

    pause(0.0001)

end