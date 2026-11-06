// Lightweight Lightbox modal for mdBook
(function() {
    function initLightbox() {
        let modal = document.getElementById('lightbox-modal');
        if (!modal) {
            modal = document.createElement('div');
            modal.id = 'lightbox-modal';
            modal.className = 'lightbox-modal';
            modal.innerHTML = `
                <span class="lightbox-close" title="Close (Esc)">&times;</span>
                <img class="lightbox-content" id="lightbox-img" alt="Enlarged Diagram" />
            `;
            document.body.appendChild(modal);

            const img = modal.querySelector('#lightbox-img');
            const closeBtn = modal.querySelector('.lightbox-close');

            function closeModal() {
                modal.classList.remove('active');
            }

            modal.addEventListener('click', function(e) {
                if (e.target !== img) {
                    closeModal();
                }
            });

            closeBtn.addEventListener('click', closeModal);

            document.addEventListener('keydown', function(e) {
                if (e.key === 'Escape' && modal.classList.contains('active')) {
                    closeModal();
                }
            });
        }

        const modalImg = document.getElementById('lightbox-img');

        // Attach click listener to images with .zoomable-image or network-topology
        const targetImages = document.querySelectorAll('.zoomable-image, img[src*="network-topology"]');
        targetImages.forEach(function(img) {
            img.setAttribute('title', 'Click to expand diagram');
            img.addEventListener('click', function(e) {
                e.preventDefault();
                modalImg.src = img.src;
                modal.classList.add('active');
            });
        });
    }

    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', initLightbox);
    } else {
        initLightbox();
    }
})();
