//
//  ViewController.swift
//  Project25
//
//  Created by nikita on 22.03.2023.
//

import UIKit
import MultipeerConnectivity


class ViewController: UICollectionViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, MCSessionDelegate, MCBrowserViewControllerDelegate {
    
    
    var images = [UIImage]()
    var peerID = MCPeerID(displayName: UIDevice.current.name)
    var mcSession: MCSession?
    var mcAdvertiserAssistant: MCAdvertiserAssistant?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Selfie Share"
        let connectionButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(showConnectionPrompt))
        let showConnectionsButton = UIBarButtonItem(title: "Connections", style: .plain, target: self, action: #selector(showConnections))
        let importPictureButton = UIBarButtonItem(barButtonSystemItem: .camera, target: self, action: #selector(importPicture))
        let shareMessageButton = UIBarButtonItem(barButtonSystemItem: .compose, target: self, action: #selector(sendMessage))
        navigationItem.rightBarButtonItems = [shareMessageButton, importPictureButton]
            
        navigationItem.leftBarButtonItems = [connectionButton, showConnectionsButton]
       
        mcSession = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
        mcSession?.delegate = self
        
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return images.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageView", for: indexPath)

        if let imageView = cell.viewWithTag(1000) as? UIImageView {
            imageView.image = images[indexPath.item]
        }

        return cell
    }
    
    @objc func showConnectionPrompt() {
        let ac = UIAlertController(title: "Connect to others", message: nil, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "Host a session", style: .default, handler: startHosting))
        ac.addAction(UIAlertAction(title: "Join a session", style: .default, handler: joinSession))
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(ac, animated: true)
    }
    
    @objc func importPicture() {
        let picker = UIImagePickerController()
        picker.allowsEditing = true
        picker.delegate = self
        present(picker, animated: true)
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let image = info[.editedImage] as? UIImage else { return }

        dismiss(animated: true)

        images.insert(image, at: 0)
        collectionView.reloadData()
        
        if let imageData = image.pngData() {
                    shareData(data: imageData)
                }

            }

            
            @objc func sendMessage() {
                let ac = UIAlertController(title: "Enter message", message: nil, preferredStyle: .alert)
                ac.addTextField()

                ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
                ac.addAction(UIAlertAction(title: "Share", style: .default, handler: { [weak self, weak ac] _ in
                    if let message = ac?.textFields?[0].text {
                        let data = Data(message.utf8)
                        self?.shareData(data: data)
                    }
                }))
                present(ac, animated: true)
            }

        
    func shareData(data: Data) {
             guard let mcSession = mcSession else { return }

             if mcSession.connectedPeers.count > 0 {
                     do {
                         try mcSession.send(data, toPeers: mcSession.connectedPeers, with: .reliable)
                     } catch {
                         let ac = UIAlertController(title: "Send error", message: error.localizedDescription, preferredStyle: .alert)
                         ac.addAction(UIAlertAction(title: "OK", style: .default))
                         present(ac, animated: true)
                 }
             }
         }
    
    @objc func showConnections() {

            var peersArray: String = "No connections"

            if let mcSession = mcSession {
                if !mcSession.connectedPeers.isEmpty {
                    peersArray = mcSession.connectedPeers.map {$0.displayName}.joined(separator: "\n")
                }
                let ac = UIAlertController(title: "Connected peers", message: peersArray, preferredStyle: .actionSheet)
                ac.popoverPresentationController?.barButtonItem = navigationItem.leftBarButtonItems?[1]
                ac.addAction(UIAlertAction(title: "OK", style: .default))
                present(ac, animated: true)
            }
        }
    
    func startHosting(action: UIAlertAction) {
        guard let mcSession = mcSession else { return }
        mcAdvertiserAssistant = MCAdvertiserAssistant(serviceType: "hws-project25", discoveryInfo: nil, session: mcSession)
        mcAdvertiserAssistant?.start()
    }

    func joinSession(action: UIAlertAction) {
        guard let mcSession = mcSession else { return }
        let mcBrowser = MCBrowserViewController(serviceType: "hws-project25", session: mcSession)
        mcBrowser.delegate = self
        present(mcBrowser, animated: true)
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {

    }

    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {

    }

    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {

    }
    
    func browserViewControllerDidFinish(_ browserViewController: MCBrowserViewController) {
        dismiss(animated: true)
    }

    func browserViewControllerWasCancelled(_ browserViewController: MCBrowserViewController) {
        dismiss(animated: true)
    }
    
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        switch state {
        case .connected:
            print("Connected: \(peerID.displayName)")

        case .connecting:
            print("Connecting: \(peerID.displayName)")

        case .notConnected:
            let ac = UIAlertController(title: "Disconnection", message: "\n No longer connected \(peerID.displayName)", preferredStyle: .alert)
             ac.addAction(UIAlertAction(title: "OK", style: .default))
             present(ac, animated: true)

        @unknown default:
            print("Unknown state received: \(peerID.displayName)")
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        DispatchQueue.main.async { [weak self] in
            if let image = UIImage(data: data) {
                self?.images.insert(image, at: 0)
                self?.collectionView.reloadData()
            }
        }
    }

}

extension ViewController: UICollectionViewDelegateFlowLayout{
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return  CGSize(width: 145, height: 145)
    }
}

