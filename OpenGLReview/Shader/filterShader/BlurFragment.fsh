precision mediump float;

uniform sampler2D in_Texture;

varying vec2 out_TexCoord;

uniform vec2 tcOffset[25];

uniform int enableBlur;
uniform int blurType;

void main(){
    
    if (enableBlur == 0) {
        vec4 textureColor = texture2D(in_Texture, out_TexCoord);
        gl_FragColor = textureColor;
        return;
    }
    
    if (blurType == 0) {
        // Blur (gaussian)
        vec4 sample_around[25];
        
        for (int i = 0; i < 25; i++)
        {
            // Sample a grid around and including our texel
            sample_around[i] = texture2D(in_Texture, out_TexCoord + tcOffset[i]);
        }
        
        // Gaussian weighting:
        // 1  4  7  4 1
        // 4 16 26 16 4
        // 7 26 41 26 7 / 273 (i.e. divide by total of weightings)
        // 4 16 26 16 4
        // 1  4  7  4 1
        
//        vec4 vFragColour = (
//                            (0.00000067  * (sample_around[0] + sample_around[6]  + sample_around[42] + sample_around[48])) +
//                            
//                            (0.00002292  * (sample_around[1] + sample_around[5]  + sample_around[7]  + sample_around[13] + sample_around[35] + sample_around[41] + sample_around[43] + sample_around[47])) +
//                            
//                            (0.00019117  * (sample_around[2] + sample_around[4] + sample_around[14] + sample_around[20] + sample_around[28] + sample_around[34] + sample_around[44] + sample_around[46])) +
//                            
//                            (0.00038771 * (sample_around[3] + sample_around[21]  + sample_around[27] + sample_around[45])) +
//                            
//                            (0.00078633 * (sample_around[8] + sample_around[12] + sample_around[36] + sample_around[40])) +
//                            
//                            (0.00655965 * (sample_around[9] + sample_around[11]  + sample_around[15]  + sample_around[19] + sample_around[29] + sample_around[33] + sample_around[37] + sample_around[39])) +
//                            
//                            (0.01330373 * (sample_around[10] + sample_around[22]  + sample_around[26]  + sample_around[38])) +
//                            
//                            (0.05472157 * (sample_around[16] + sample_around[18]  + sample_around[37]  + sample_around[39])) +
//                            
//                            (0.11098164 * (sample_around[17] + sample_around[23]  + sample_around[25]  + sample_around[31])) +
//                            
//                            (0.22508352 * sample_around[24])
//                            
//                            );
        
        vec4 vFragColour = (
                            (1.0  * (sample_around[0] + sample_around[4]  + sample_around[20] + sample_around[24])) +
                            (4.0  * (sample_around[1] + sample_around[3]  + sample_around[5]  + sample_around[9] + sample_around[15] + sample_around[19] + sample_around[21] + sample_around[23])) +
                            (7.0  * (sample_around[2] + sample_around[10] + sample_around[14] + sample_around[22])) +
                            (16.0 * (sample_around[6] + sample_around[8]  + sample_around[16] + sample_around[18])) +
                            (26.0 * (sample_around[7] + sample_around[11] + sample_around[13] + sample_around[17])) +
                            (41.0 * sample_around[12])
                            ) / 273.0;
        
        gl_FragColor = vFragColour;
    }
    else if (blurType == 1){
        //Blur (median filter)
        vec4 vFragColour = vec4(0.0);
        
        for (int i = 0; i < 25; i++)
        {
            // Sample a grid around and including our texel
            vFragColour += texture2D(in_Texture, out_TexCoord + tcOffset[i]);
        }
        
        vFragColour = vec4(vFragColour.r/25.0, vFragColour.g/25.0, vFragColour.b/25.0, vFragColour.w/25.0);
        
        gl_FragColor = vFragColour;
    }
    else if (blurType == 2){
        //sharpen
        vec4 sample_around[25];
        
        for (int i = 0; i < 25; i++)
        {
            // Sample a grid around and including our texel
            sample_around[i] = texture2D(in_Texture, out_TexCoord + tcOffset[i]);
        }
        
        // Sharpen weighting:
        // -1 -1 -1 -1 -1
        // -1 -1 -1 -1 -1
        // -1 -1 25 -1 -1
        // -1 -1 -1 -1 -1
        // -1 -1 -1 -1 -1
        
        vec4 vFragColour = 25.0 * sample_around[12];
        
        for (int i = 0; i < 25; i++)
        {
            if (i != 12)
                vFragColour -= sample_around[i];
        }
        gl_FragColor = vFragColour;
    }
    else if (blurType == 3){
        //Dilate
        vec4 sample_around[25];
        vec4 maxValue = vec4(0.0);
        
        for (int i = 0; i < 25; i++)
        {
            // Sample a grid around and including our texel
            sample_around[i] = texture2D(in_Texture, out_TexCoord + tcOffset[i]);
            
            // Keep the maximum value
            maxValue = max(sample_around[i], maxValue);
        }
        
        vec4 vFragColour = maxValue;
        gl_FragColor = vFragColour;
    }
    else if (blurType == 4){
        //erode
        vec4 sample_around[25];
        vec4 minValue = vec4(1.0);
        
        for (int i = 0; i < 25; i++)
        {
            // Sample a grid around and including our texel
            sample_around[i] = texture2D(in_Texture, out_TexCoord + tcOffset[i]);
            
            // Keep the minimum value
            minValue = min(sample_around[i], minValue);
        }
        
        vec4 vFragColour = minValue;
        gl_FragColor = vFragColour;
    }
}
