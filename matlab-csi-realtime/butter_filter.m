function ret = butter_filter(data)
    [b, a] = butter(9, .5);
    ret = filter(b, a, data);
end

