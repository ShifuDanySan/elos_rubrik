const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

exports.sincronizarEmail = functions.auth.user().onUpdate(async (change) => {
    // En v1, el parámetro 'change' contiene 'before' y 'after'
    const nuevoEmail = change.email;
    const anteriorEmail = change.before ? change.before.email : null;
    const uid = change.uid;

    if (nuevoEmail && nuevoEmail !== anteriorEmail) {
        try {
            await admin.firestore().collection("usuarios").doc(uid).update({
                email: nuevoEmail,
                actualizado: new Date().toISOString()
            });
            console.log("Email sincronizado correctamente en Firestore");
        } catch (error) {
            console.error("Error al actualizar Firestore:", error);
        }
    }
    return null;
});