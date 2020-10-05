.PHONY: combine pdf docx clean

combine: generated/router-lab.md

pdf: generated/router-lab.pdf

docx: generated/router-lab.docx

generated/router-lab.md: docs mkdocs.yml
	mkdir -p generated
	mkdocscombine -d -o $@
	bash ./pandoc/remove_duplicate_title.sh $@

generated/router-lab.docx: generated/router-lab.md pandoc/docx.yml
	pandoc --defaults pandoc/docx.yml -s -o $@ $<

generated/router-lab.pdf: generated/router-lab.md pandoc/pdf.yml
	pandoc --defaults pandoc/pdf.yml -o $@ $<

clean:
	rm -rf generated
