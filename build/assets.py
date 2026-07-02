import fitz
pdf = r"C:\Users\office\cadenza-brochure\CADENZA-Brochure.pdf"
doc = fitz.open(pdf)
outdir = r"C:\Users\office\cadenza-brochure\build"
def save_transparent(xref, path):
    info = doc.extract_image(xref)
    sm = info.get("smask", 0)
    base = fitz.Pixmap(doc, xref)
    if base.alpha:
        base.save(path); print("saved(a)", path, base.width, base.height); return
    if sm:
        mask = fitz.Pixmap(doc, sm)
        pm = fitz.Pixmap(base, mask)
        pm.save(path); print("saved(mask)", path, pm.width, pm.height, "alpha", pm.alpha)
    else:
        base.save(path); print("saved", path, base.width, base.height)
save_transparent(97, outdir + r"\map.png")
save_transparent(6,  outdir + r"\logo_dark.png")
