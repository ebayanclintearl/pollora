(function () {
  const currentPage = window.location.pathname.split("/").pop() || "index.html";

  document
    .querySelectorAll(".top-nav a, .site-footer a")
    .forEach((link) => {
      const href = link.getAttribute("href");
      if (href === currentPage) {
        link.setAttribute("aria-current", "page");
      }
    });

  const topButton = document.querySelector(".scroll-top");
  if (!topButton) {
    return;
  }

  const updateTopButton = () => {
    topButton.dataset.visible = window.scrollY > 520 ? "true" : "false";
  };

  topButton.addEventListener("click", () => {
    window.scrollTo({ top: 0, behavior: "smooth" });
  });

  window.addEventListener("scroll", updateTopButton, { passive: true });
  updateTopButton();
})();
