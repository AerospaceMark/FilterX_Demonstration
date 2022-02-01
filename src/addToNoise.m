function n = addToNoise(n,noiseFunc,noiseFuncArg)

    n = circshift(n,1);

    n(1) = noiseFunc(noiseFuncArg);

end