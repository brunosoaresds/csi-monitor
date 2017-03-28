function csiAngle = csi_angle( csi )
    csiAngle = arrayfun(@calculeCsiAngle, csi);
    
    function x = calculeCsiAngle(csi)
        x = atan(imag(csi)/real(csi));
    end
end

