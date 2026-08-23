import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "previewContainer", "uploadText"]

  handleFiles(event) {
    let files = Array.from(event.target.files);
    if (files.length === 0) {
      this.previewContainerTarget.style.display = 'none';
      this.uploadTextTarget.textContent = "Click to select new images";
      return;
    }

    files.sort((a, b) => a.name.localeCompare(b.name));

    const dt = new DataTransfer();
    files.forEach(file => dt.items.add(file));
    this.inputTarget.files = dt.files;

    this.previewContainerTarget.innerHTML = '';
    this.previewContainerTarget.style.display = 'grid';
    this.uploadTextTarget.textContent = files.length + " file" + (files.length > 1 ? "s" : "") + " selected for upload";

    files.forEach((file, index) => {
      const reader = new FileReader();
      reader.onload = (e) => {
        const wrapper = document.createElement('div');
        wrapper.style.position = 'relative';
        
        const img = document.createElement('img');
        img.src = e.target.result;
        img.style.width = '100%';
        img.style.aspectRatio = '1/1';
        img.style.objectFit = 'cover';
        img.style.borderRadius = '6px';
        img.style.border = index === 0 ? '2px solid #c4933f' : '1px solid #2a251e';
        
        if (index === 0) {
          const badge = document.createElement('span');
          badge.textContent = 'COVER';
          badge.style.position = 'absolute';
          badge.style.bottom = '4px';
          badge.style.left = '50%';
          badge.style.transform = 'translateX(-50%)';
          badge.style.background = '#c4933f';
          badge.style.color = '#000';
          badge.style.fontSize = '9px';
          badge.style.fontWeight = 'bold';
          badge.style.padding = '1px 4px';
          badge.style.borderRadius = '2px';
          wrapper.appendChild(badge);
        }

        wrapper.appendChild(img);
        this.previewContainerTarget.appendChild(wrapper);
      }
      reader.readAsDataURL(file);
    });
  }
}
