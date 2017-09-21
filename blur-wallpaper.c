#include <MagickWand/MagickWand.h>
#include <stdlib.h>

extern int BlurWallpaper (const char *Input, const char *Output, double Sigma)
{
    MagickWandGenesis();
    MagickWand *Wand = NewMagickWand();

    MagickBooleanType Status = MagickReadImage(Wand,
        Input);
    if (Status == MagickFalse)
    {
        return 1;
    }

    MagickBlurImage(Wand, 0, Sigma);

    MagickWriteImage(Wand, Output);

    return 0;
}
