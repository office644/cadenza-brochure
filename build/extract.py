import fitz, os
pdf = r"C:\Users\office\cadenza-brochure\CADENZA-Brochure.pdf"
out = r"C:\Users\office\cadenza-brochure\build\assets"
doc = fitz.open(pdf)
print("pages:", len(doc), "| page rect:", doc[0].rect)
seen=set()
for pno in range(len(doc)):
    for img in doc.get_page_images(pno, full=True):
        xref=img[0]
        if xref in seen: continue
        seen.add(xref)
        try:
            pix=fitz.Pixmap(doc, xref)
            if pix.n-pix.alpha>=4: pix=fitz.Pixmap(fitz.csRGB,pix)
            fn=f"img_p{pno+1}_x{xref}_{pix.width}x{pix.height}.png"
            pix.save(os.path.join(out,fn))
            print("IMG page",pno+1,"xref",xref,"size",pix.width,"x",pix.height)
            pix=None
        except Exception as e:
            print("err",xref,e)
