#include <MagickWand/MagickWand.h>
#include <stdlib.h>

extern int BlurWallpaper (const char *Input, const char *Output, double Range, double Sigma)
{
    MagickWandGenesis();
    MagickWand *Wand = NewMagickWand();

    MagickBooleanType Status = MagickReadImage(Wand, Input);
    if (Status == MagickFalse)
    {
        fprintf(stderr, "blur: could not find image\n");
        return 1;
    }

    Status = MagickBlurImage(Wand, Range, Sigma);
    if (Status == MagickFalse)
    {
        fprintf(stderr, "blur: could not blur image\n");
        return 2;
    }

    Status = MagickWriteImage(Wand, Output);
    if (Status == MagickFalse)
    {
        fprintf(stderr, "blur: could not write image\n");
        return 3;
    }

    return 0;
}
