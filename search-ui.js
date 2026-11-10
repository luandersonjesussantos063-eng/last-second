import {
  beginSearch,
  inspectPart,
  finishSearch,
  returnSearch,
  searchTarget,
  searchedVehicle,
} from "./blitz-search.js?v=2.23.0";
export function createSearchUI({ getSim, release, refresh, audio }) {
  const $ = (id) => document.getElementById(id),
    dialog = $("searchDialog");
  function update() {
    const s = getSim(),
      r = s.blitzSearch;
    if (!r) return;
    $("searchVehicle").textContent = "Fiscalização · " + r.plate;
    $("searchResult").textContent = r.result;
    const done = r.checks.length === 3;
    $("releaseSearch").disabled =
      $("fineSearch").disabled =
      $("retainSearch").disabled =
        !done;
    $("searchProgress").textContent =
      `${r.checks.length}/3 verificações · ${r.checks.map((p) => ({ documents: "Documentos", cabin: "Cabine", cargo: "Carga/porta-malas" })[p]).join(" · ")}`;
  }
  function open() {
    if (!beginSearch(getSim())) return false;
    release();
    dialog.showModal();
    update();
    return true;
  }
  for (const [id, part] of [
    ["searchDocuments", "documents"],
    ["searchCabin", "cabin"],
    ["searchCargo", "cargo"],
  ])
    $(id).onclick = () => {
      inspectPart(getSim(), part);
      audio.emit("ui");
      update();
    };
  for (const [id, d] of [
    ["releaseSearch", "release"],
    ["fineSearch", "fine"],
    ["retainSearch", "retain"],
  ])
    $(id).onclick = () => {
      if (finishSearch(getSim(), d)) {
        dialog.close();
        release();
        refresh();
      } else {
        $("searchResult").textContent =
          "Conclua as verificações ou aguarde disponibilidade do guincho.";
      }
    };
  function close() {
    returnSearch(getSim());
    dialog.close();
    release();
    refresh();
  }
  $("returnSearch").onclick = close;
  dialog.addEventListener("cancel", (e) => {
    e.preventDefault();
    close();
  });
  return {
    open,
    close,
    update,
    get isOpen() {
      return dialog.open;
    },
  };
}
