void Lerp5Colors_float(float value, float3 color1, float3 color2, float3 color3, float3 color4, float3 color5, out float3 Out)
{
    if (value < 0.25)
    {
        Out =  lerp(color1, color2, value * 4.0);
    }
    else if (value < 0.5)
    {
        Out = lerp(color2, color3, (value - 0.25) * 4.0);
    }
    else if (value < 0.75)
    {
        Out = lerp(color3, color4, (value - 0.5) * 4.0);
    }
    else
    {
        Out = lerp(color4, color5, (value - 0.75) * 4.0);
    }


}