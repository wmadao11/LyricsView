//
//  LyricsView.swift
//  LyricsView
//
//  Created by Aqua on 21/10/2017.
//  Copyright © 2017 Aqua. All rights reserved.
//

import UIKit

public class LyricsView: UIView {
    
    public var lyrics: LyricsModelProtocol? {
        didSet {
            tableView.reloadData()
        }
    }
    
    public var lineHeight: CGFloat = 40 {
        didSet {
            tableView.rowHeight = lineHeight
        }
    }
    
    public var font: UIFont = UIFont.systemFont(ofSize: UIFont.systemFontSize) {
        didSet {
            tableView.reloadData()
        }
    }
    
    public var time: TimeInterval = 0 {
        didSet {
            updateProgress()
        }
    }
    
    private var currentLineIndex = -1 {
        willSet {
            if !tableView.isDragging && !tableView.isTracking {
                /// if currentLineIndex < 0, dont animate.
                let animated = currentLineIndex >= 0
                tableView.scrollToRow(at: IndexPath(row: newValue, section: 0), at: .middle, animated: animated)
            }
        }
    }
    
    private let tableView = UITableView(frame: .zero, style: .plain)
    
    //MARK: Init / Deinit
    
    private func commonInit() {
        
        backgroundColor = .clear
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.estimatedSectionFooterHeight = 0
        tableView.estimatedSectionHeaderHeight = 0
        
        tableView.register(LyricsTableViewCell.self, forCellReuseIdentifier: "LyricsTableViewCell")
        tableView.estimatedRowHeight = 0
        tableView.rowHeight          = lineHeight
        tableView.backgroundColor = .clear

        tableView.tableFooterView = UIView()
        tableView.showsVerticalScrollIndicator = false
        if #available(iOS 11.0, *) {
            tableView.contentInsetAdjustmentBehavior = .never
        }
        
        addSubview(tableView)
        let edges: [NSLayoutAttribute] = [.top, .bottom, .left, .right]
        edges.forEach { (edge) in
            NSLayoutConstraint(item: tableView,
                               attribute: edge,
                               relatedBy: .equal,
                               toItem: self,
                               attribute: edge,
                               multiplier: 1,
                               constant: 0).isActive = true
        }
        
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        tableView.contentInset = UIEdgeInsets(top: (bounds.height - lineHeight) / 2, left: 0, bottom: (bounds.height - lineHeight) / 2, right: 0)
    }
    
    public override func didMoveToSuperview() {
        super.didMoveToSuperview()
        tableView.separatorStyle  = .none
    }
}

/// MARK: Private Methods
extension LyricsView {
    
    fileprivate func updateProgress() {
        
        guard let lyrics = self.lyrics else { return }
        
        func isCurrentLine(lineIndex: Int) -> Bool {
            let lastLineIndex = lineIndex + 1
            let isLastLine = lyrics.lines.count == lastLineIndex
            let line = lyrics.lines[lineIndex]
            if isLastLine && time > line.beginTime {
                return true
            } else if time > line.beginTime && lyrics.lines[lastLineIndex].beginTime >= time {
                return true
            }
            return false
        }
        
        /// find out index of current line
        var lineIndex = 0
        if currentLineIndex >= 0 && isCurrentLine(lineIndex: currentLineIndex) {
            lineIndex = currentLineIndex
        } else {
            /// if current time is not in current line
            for index in 0..<lyrics.lines.count {
                if isCurrentLine(lineIndex: index) {
                    lineIndex = index
                    break
                }
            }
        }
        
        /// update cell's time
        if lineIndex != self.currentLineIndex {
            currentLineIndex = lineIndex
            tableView.indexPathsForVisibleRows?.forEach({ (indexPath) in
                if let cell = tableView.cellForRow(at: indexPath) as? LyricsTableViewCell {
                    cell.lyricsLabel.currentTime = max(time, 0)
                }
            })
        } else {
            let currentLineIndexPath = IndexPath(row: currentLineIndex, section: 0)
            if let cell = tableView.cellForRow(at: currentLineIndexPath) as? LyricsTableViewCell {
                cell.lyricsLabel.currentTime = max(time, 0)
            }
        }
    }
}

extension LyricsView: UITableViewDataSource {
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return lyrics?.lines.count ?? 0
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "LyricsTableViewCell", for: indexPath) as! LyricsTableViewCell
        let lineModel = lyrics!.lines[indexPath.row]
        cell.lyricsLabel.font = font
        cell.lyricsLabel.line = lineModel
        cell.lyricsLabel.currentTime = max(time, 0)
        return cell
    }
    
    public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return nil
    }
    
    public func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return nil
    }
}

extension LyricsView: UITableViewDelegate {
    
    public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return .leastNonzeroMagnitude
    }
    
    public func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return .leastNonzeroMagnitude
    }
}
