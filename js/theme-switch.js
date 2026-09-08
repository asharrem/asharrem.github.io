(function () {
  var KEY = "asharrem-theme";
  var themes = {
    nxpt: "css/nxpt.css",
    material: "css/material.css"
  };
  var theme = localStorage.getItem(KEY) || "nxpt";
  if (!themes[theme]) theme = "nxpt";

  document.documentElement.setAttribute("data-theme", theme);

  var link = document.getElementById("theme-stylesheet");
  if (link) link.href = themes[theme];

  document.addEventListener("DOMContentLoaded", function () {
    var select = document.getElementById("theme-select");
    if (!select) return;
    select.value = theme;
    select.addEventListener("change", function () {
      var next = select.value;
      if (!themes[next]) next = "nxpt";
      localStorage.setItem(KEY, next);
      document.documentElement.setAttribute("data-theme", next);
      if (link) link.href = themes[next];
    });
  });
})();
