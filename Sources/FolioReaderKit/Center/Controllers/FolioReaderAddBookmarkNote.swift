//
//  FolioReaderAddBookmarkNote.swift
//  FolioReaderKit
//
//  Created by ShuichiNagao on 2018/05/06.
//

import UIKit

class FolioReaderAddBookmarkNote: UIViewController {

    let textView = UITextView()
    let bookmarkLabel = UILabel()
    let scrollView = UIScrollView()
    let containerView = UIView()
    var bookmark: FolioReaderBookmark
    var bookmarkSaved = false
    var isEditBookmark = false
    var resizedTextView = false
    
    private var folioReader: FolioReader
    private var readerConfig: FolioReaderConfig
    
    init(withBookmark bookmark: FolioReaderBookmark, folioReader: FolioReader, readerConfig: FolioReaderConfig) {
        self.folioReader = folioReader
        self.bookmark = bookmark
        self.readerConfig = readerConfig
        
        super.init(nibName: nil, bundle: Bundle.frameworkBundle())
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("storyboards are incompatible with truth and beauty")
    }
    
    // MARK: - life cycle methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setCloseButton(withConfiguration: readerConfig)
        prepareScrollView()
        configureTextView()
        configureLabel()
        configureNavBar()
        configureKeyboardObserver()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        textView.becomeFirstResponder()
        setNeedsStatusBarAppearanceUpdate()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        scrollView.frame = view.bounds
        containerView.frame = view.bounds
        scrollView.contentSize = view.bounds.size
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if !bookmarkSaved && !isEditBookmark {
            guard let currentPage = folioReader.readerCenter?.currentPage else { return }
            currentPage.webView?.js("removeThisBookmark()")
        }
    }
    
    // MARK: - private methods
    
    private func prepareScrollView(){
        scrollView.delegate = self as UIScrollViewDelegate
        scrollView.contentSize = CGSize.init(width: view.frame.width, height: view.frame.height )
        scrollView.bounces = false
        
        containerView.backgroundColor = .white
        scrollView.addSubview(containerView)
        view.addSubview(scrollView)
        
        let leftConstraint = NSLayoutConstraint(item: scrollView, attribute: .left, relatedBy: .equal, toItem: view, attribute: .left, multiplier: 1.0, constant: 0)
        let rightConstraint = NSLayoutConstraint(item: scrollView, attribute: .right, relatedBy: .equal, toItem: view, attribute: .right, multiplier: 1.0, constant: 0)
        let topConstraint = NSLayoutConstraint(item: scrollView, attribute: .top, relatedBy: .equal, toItem: view, attribute: .top, multiplier: 1, constant: 0)
        let botConstraint = NSLayoutConstraint(item: scrollView, attribute: .bottom, relatedBy: .equal, toItem: view, attribute: .bottom, multiplier: 1, constant: 0)
        
        view.addConstraints([leftConstraint, rightConstraint, topConstraint, botConstraint])
    }
    
    private func configureTextView(){
        textView.delegate = self
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.textColor = .black
        textView.backgroundColor = .clear
        textView.font = UIFont.boldSystemFont(ofSize: 15)
        containerView.addSubview(textView)
        
        if isEditBookmark {
             textView.text = bookmark.title
        }
        
        let leftConstraint = NSLayoutConstraint(item: textView, attribute: .left, relatedBy: .equal, toItem: containerView, attribute: .left, multiplier: 1.0, constant: 20)
        let rightConstraint = NSLayoutConstraint(item: textView, attribute: .right, relatedBy: .equal, toItem: containerView, attribute: .right, multiplier: 1.0, constant: -20)
        let topConstraint = NSLayoutConstraint(item: textView, attribute: .top, relatedBy: .equal, toItem: containerView, attribute: .top, multiplier: 1, constant: 100)
        let heiConstraint = NSLayoutConstraint(item: textView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1, constant: view.frame.height - 100)
        containerView.addConstraints([leftConstraint, rightConstraint, topConstraint, heiConstraint])
    }
    
    private func configureLabel() {
        bookmarkLabel.translatesAutoresizingMaskIntoConstraints = false
        bookmarkLabel.numberOfLines = 3
        bookmarkLabel.font = UIFont.systemFont(ofSize: 15)
        bookmarkLabel.text = bookmark.title
        
        containerView.addSubview(self.bookmarkLabel)
        
        let leftConstraint = NSLayoutConstraint(item: bookmarkLabel, attribute: .left, relatedBy: .equal, toItem: containerView, attribute: .left, multiplier: 1.0, constant: 20)
        let rightConstraint = NSLayoutConstraint(item: bookmarkLabel, attribute: .right, relatedBy: .equal, toItem: containerView, attribute: .right, multiplier: 1.0, constant: -20)
        let topConstraint = NSLayoutConstraint(item: bookmarkLabel, attribute: .top, relatedBy: .equal, toItem: containerView, attribute: .top, multiplier: 1, constant: 20)
        let heiConstraint = NSLayoutConstraint(item: bookmarkLabel, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1, constant: 70)
        
        containerView.addConstraints([leftConstraint, rightConstraint, topConstraint, heiConstraint])
    }
    
    private func configureNavBar() {
        //let navBackground = folioReader.isNight(self.readerConfig.nightModeNavBackground, self.readerConfig.daysModeNavBackground)
        let navBackground = self.readerConfig.themeModeNavBackground[folioReader.themeMode]
        let tintColor = readerConfig.tintColor
        let navText = folioReader.isNight(UIColor.white, UIColor.black)
        let font = UIFont(name: "Avenir-Light", size: 17) ?? .systemFont(ofSize: 17)
        setTranslucentNavigation(false, color: navBackground, tintColor: tintColor, titleColor: navText, andFont: font)
        
        let titleAttrs = [NSAttributedString.Key.foregroundColor: readerConfig.tintColor]
        let saveButton = UIBarButtonItem(title: readerConfig.localizedSave, style: .plain, target: self, action: #selector(saveNote(_:)))
        saveButton.setTitleTextAttributes(titleAttrs, for: UIControl.State())
        navigationItem.rightBarButtonItem = saveButton
    }
    
    private func configureKeyboardObserver() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name:UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name:UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc private func keyboardWillShow(notification: NSNotification) {
        //give room at the bottom of the scroll view, so it doesn't cover up anything the user needs to tap
        guard let userInfo = notification.userInfo else { return }
        guard let keyboardFrameValue = userInfo[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue else { return }
        var keyboardFrame = self.view.convert(keyboardFrameValue.cgRectValue, from: nil)
        
        var contentInset = self.scrollView.contentInset
        contentInset.bottom = keyboardFrame.size.height
        self.scrollView.contentInset = contentInset
    }
    
    @objc private func keyboardWillHide(notification:NSNotification){
        self.scrollView.contentInset = UIEdgeInsets.zero
    }
    
    @objc private func saveNote(_ sender: UIBarButtonItem) {
        if !textView.text.isEmpty {
            bookmark.title = textView.text
            
            let isEdit = isEditBookmark
            let provider = folioReader.bookmarkProvider
            let reader = folioReader
            let bm = bookmark
            Task {
                if isEdit {
                    await provider?.updateBookmark(pos: bm.pos ?? "", title: bm.title, for: reader)
                } else {
                    _ = try? await provider?.addBookmark(bm, for: reader)
                }
            }
            bookmarkSaved = true
        }
        
        dismiss()
    }
}

// MARK: - UITextViewDelegate
extension FolioReaderAddBookmarkNote: UITextViewDelegate {
    
    func textViewDidChange(_ textView: UITextView) {
        let fixedWidth = textView.frame.size.width
        textView.sizeThatFits(CGSize(width: fixedWidth, height: CGFloat.greatestFiniteMagnitude))
        let newSize = textView.sizeThatFits(CGSize(width: fixedWidth, height: CGFloat.greatestFiniteMagnitude))
        var newFrame = textView.frame
        newFrame.size = CGSize(width: max(newSize.width, fixedWidth), height: newSize.height + 15)
        textView.frame = newFrame;
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        textView.frame.size.height = textView.frame.height + 30

        if resizedTextView {
            scrollView.scrollRectToVisible(textView.frame, animated: true)
        }
        else{
            resizedTextView = true
        }
        
        return true
    }
}
