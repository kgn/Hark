//
//  UIView+AutoLayout.swift
//  UIView+AutoLayout
//
//  Created by David Keegan on 9/14/14.
//  Copyright (c) 2014 David Keegan. All rights reserved.
//

import UIKit

extension UIView {

    // MARK: - Pin: Superview

    func pinToEdgesOfSuperview(offset: CGFloat = 0, priority: UILayoutPriority? = nil) -> (top: NSLayoutConstraint, right: NSLayoutConstraint, bottom: NSLayoutConstraint, left: NSLayoutConstraint) {
        return (
            self.pinToTopEdgeOfSuperview(offset: offset, priority: priority),
            self.pinToRightEdgeOfSuperview(offset: offset, priority: priority),
            self.pinToBottomEdgeOfSuperview(offset: offset, priority: priority),
            self.pinToLeftEdgeOfSuperview(offset: offset, priority: priority)
        )
    }

    func pinToTopEdgeOfSuperview(offset: CGFloat = 0, priority: UILayoutPriority? = nil) -> NSLayoutConstraint {
        return self.constrainEdgeAttribute(.Top, offset: offset, priority: priority)
    }

    func pinToRightEdgeOfSuperview(offset: CGFloat = 0, priority: UILayoutPriority? = nil) -> NSLayoutConstraint {
        return self.constrainEdgeAttribute(.Right, offset: offset, priority: priority)
    }

    func pinToBottomEdgeOfSuperview(offset: CGFloat = 0, priority: UILayoutPriority? = nil) -> NSLayoutConstraint {
        return self.constrainEdgeAttribute(.Bottom, offset: offset, priority: priority)
    }

    func pinToLeftEdgeOfSuperview(offset: CGFloat = 0, priority: UILayoutPriority? = nil) -> NSLayoutConstraint {
        return self.constrainEdgeAttribute(.Left, offset: offset, priority: priority)
    }

    func pinToSideEdgesOfSuperview(offset: CGFloat = 0, priority: UILayoutPriority? = nil) -> (left: NSLayoutConstraint, right: NSLayoutConstraint) {
        return (
            self.pinToLeftEdgeOfSuperview(offset: offset, priority: priority),
            self.pinToRightEdgeOfSuperview(offset: offset, priority: priority)
        )
    }

    // MARK: - Pin: Edges

    func pinTopEdgeToTopEdgeOfItem(item: AnyObject, offset: CGFloat = 0, priority: UILayoutPriority? = nil) -> NSLayoutConstraint {
        return self.constrainAttribute(.Top, toAttribute: .Top, ofItem: item, offset: -offset, priority: priority)
    }

    func pinRightEdgeToRightEdgeOfItem(item: AnyObject, offset: CGFloat = 0, priority: UILayoutPriority? = nil) -> NSLayoutConstraint {
        return self.constrainAttribute(.Right, toAttribute: .Right, ofItem: item, offset: offset, priority: priority)
    }

    func pinBottomEdgeToBottomEdgeOfItem(item: AnyObject, offset: CGFloat = 0, priority: UILayoutPriority? = nil) -> NSLayoutConstraint {
        return self.constrainAttribute(.Bottom, toAttribute: .Bottom, ofItem: item, offset: offset, priority: priority)
    }

    func pinLeftEdgeToLeftEdgeOfItem(item: AnyObject, offset: CGFloat = 0, priority: UILayoutPriority? = nil) -> NSLayoutConstraint {
        return self.constrainAttribute(.Left, toAttribute: .Left, ofItem: item, offset: -offset, priority: priority)
    }

    // MARK: - Center

    func centerInSuperview(offset: CGFloat = 0, priority: UILayoutPriority? = nil) -> (horizontal: NSLayoutConstraint, vertical: NSLayoutConstraint){
        return (
            self.centerHorizontallyInSuperview(offset: offset, priority: priority),
            self.centerVerticallyInSuperview(offset: offset, priority: priority)
        )
    }

    func centerHorizontallyInSuperview(offset: CGFloat = 0, priority: UILayoutPriority? = nil) -> NSLayoutConstraint {
        return self.constrainEdgeAttribute(.CenterX, offset: offset, priority: priority)
    }

    func centerVerticallyInSuperview(offset: CGFloat = 0, priority: UILayoutPriority? = nil) -> NSLayoutConstraint {
        return self.constrainEdgeAttribute(.CenterY, offset: offset, priority: priority)
    }

    func centerViewsHorizontally(views: [UIView], separation: CGFloat = 0, priority: UILayoutPriority? = nil) {
        assert(views.count > 0, "Can only distribute 1 or more views")

        // odd number of views
        if views.count % 2  == 0 {
            let centerIndex = views.count/2
            views[centerIndex].centerHorizontallyInSuperview()

            let rightViews = Array(views[centerIndex+1...views.count-1])
            if rightViews.count > 0 {
                views[centerIndex].positionViewsToTheRight(rightViews, offset: separation, priority: priority)
            }

            let leftViews = Array(views[0...centerIndex-1])
            if leftViews.count > 0{
                views[centerIndex].positionViewsToTheLeft(leftViews, offset: separation, priority: priority)
            }
        } else {
            let rightIndex = views.count/2
            let leftIndex = rightIndex-1

            views[leftIndex].constrainAttribute(.Right, toAttribute: .CenterX, ofItem: self, relatedBy: .LessThanOrEqual, offset:-separation/2, priority: priority)
            views[rightIndex].constrainAttribute(.Left, toAttribute: .CenterX, ofItem: self, relatedBy: .LessThanOrEqual, offset:separation/2, priority: priority)

            let rightViews = Array(views[rightIndex+1...views.count-1])
            if rightViews.count > 0 {
                views[rightIndex].positionViewsToTheRight(rightViews, offset: separation, priority: priority)
            }

            let leftViews = Array(views[0...leftIndex-1])
            if leftViews.count > 0 {
                views[leftIndex].positionViewsToTheLeft(leftViews, offset: separation, priority: priority)
            }
        }
    }

    func centerViewsVertically(views: [UIView], separation: CGFloat = 0, priority: UILayoutPriority? = nil) {
        assert(views.count > 0, "Can only distribute 1 or more views")

        // odd number of views
        if views.count % 2  == 0 {
            let centerIndex = views.count/2
            views[centerIndex].centerVerticallyInSuperview()

            let belowViews = Array(views[centerIndex+1...views.count-1])
            if belowViews.count > 0 {
                views[centerIndex].positionViewsBelow(belowViews, offset: separation, priority: priority)
            }

            let aboveViews = Array(views[0...centerIndex-1])
            if aboveViews.count > 0{
                views[centerIndex].positionViewsAbove(aboveViews, offset: separation, priority: priority)
            }
        }else{
            let belowIndex = views.count/2
            let aboveIndex = belowIndex-1

            views[aboveIndex].constrainAttribute(.Bottom, toAttribute: .CenterY, ofItem: self, relatedBy: .LessThanOrEqual, offset:-separation/2, priority: priority)
            views[belowIndex].constrainAttribute(.Top, toAttribute: .CenterY, ofItem: self, relatedBy: .LessThanOrEqual, offset:separation/2, priority: priority)

            let belowViews = Array(views[belowIndex+1...views.count-1])
            if belowViews.count > 0 {
                views[belowIndex].positionViewsBelow(belowViews, offset: separation, priority: priority)
            }

            let aboveViews = Array(views[0...aboveIndex-1])
            if aboveViews.count > 0 {
                views[aboveIndex].positionViewsAbove(aboveViews, offset: separation, priority: priority)
            }
        }
    }

    // MARK: - Size

    func sizeToWidth(width: CGFloat, priority: UILayoutPriority? = nil) -> NSLayoutConstraint{
        return self.constrainSizeAttribute(.Width, size:width)
    }

    func sizeToHeight(height: CGFloat, priority: UILayoutPriority? = nil) -> NSLayoutConstraint{
        return self.constrainSizeAttribute(.Height, size:height)
    }

    func sizeToWidthOfItem(item: AnyObject, offset: CGFloat = 0, priority: UILayoutPriority? = nil) -> NSLayoutConstraint {
        return self.constrainAttribute(.Width, toAttribute:.Width, ofItem:item, offset:-(offset*2))
    }

    func sizeToHeightOfItem(item: AnyObject, offset: CGFloat = 0, priority: UILayoutPriority? = nil) -> NSLayoutConstraint {
        return self.constrainAttribute(.Height, toAttribute:.Height, ofItem:item, offset:-(offset*2))
    }

    func sizeHeightToWidthOfItem(item: AnyObject) -> NSLayoutConstraint {
        return self.constrainAttribute(.Height, toAttribute:.Width, ofItem:item)
    }

    func sizeWidthToHeightOfItem(item: AnyObject) -> NSLayoutConstraint {
        return self.constrainAttribute(.Width, toAttribute:.Height, ofItem:item)
    }

    func sizeToWidthAndHeight(toSize: CGFloat) -> (width: NSLayoutConstraint, height: NSLayoutConstraint) {
        return (
            self.sizeToWidth(toSize),
            self.sizeToHeight(toSize)
        )
    }

    func sizeToWidthAndHeightOfItem(item: AnyObject, offset: CGFloat = 0, priority: UILayoutPriority? = nil) -> (width: NSLayoutConstraint, height: NSLayoutConstraint) {
        return (
            self.sizeToWidthOfItem(item, offset: offset, priority: priority),
            self.sizeToHeightOfItem(item, offset: offset, priority: priority)
        )
    }

    // MARK: - Position

    func positionAboveItem(item: AnyObject, offset: CGFloat = 0, priority: UILayoutPriority? = nil) -> NSLayoutConstraint {
        return self.constrainAttribute(.Bottom, toAttribute:.Top, ofItem:item, offset:-offset, priority: priority)
    }

    func positionToTheRightOfItem(item: AnyObject, offset: CGFloat = 0, priority: UILayoutPriority? = nil) -> NSLayoutConstraint {
        return self.constrainAttribute(.Left, toAttribute:.Right, ofItem:item, offset:offset, priority: priority)
    }

    func positionBelowItem(item: AnyObject, offset: CGFloat = 0, priority: UILayoutPriority? = nil) -> NSLayoutConstraint {
        return self.constrainAttribute(.Top, toAttribute:.Bottom, ofItem:item, offset:offset, priority: priority)
    }

    func positionToTheLeftOfItem(item: AnyObject, offset: CGFloat = 0, priority: UILayoutPriority? = nil) -> NSLayoutConstraint {
        return self.constrainAttribute(.Right, toAttribute:.Left, ofItem:item, offset:-offset, priority: priority)
    }

    func positionViewsAbove(views: [UIView], offset: CGFloat = 0, priority: UILayoutPriority? = nil) {
        assert(views.count > 0, "Can only distribute 1 or more views")

        var lastView: UIView = self
        for view in reverse(views) {
            view.positionAboveItem(lastView, offset:offset, priority: priority)
            lastView = view
        }
    }

    func positionViewsToTheRight(views: [UIView], offset: CGFloat = 0, priority: UILayoutPriority? = nil) {
        assert(views.count > 0, "Can only distribute 1 or more views")

        var lastView: UIView = self
        for view in views {
            view.positionToTheRightOfItem(lastView, offset:offset, priority: priority)
            lastView = view
        }
    }

    func positionViewsBelow(views: [UIView], offset: CGFloat = 0, priority: UILayoutPriority? = nil) {
        assert(views.count > 0, "Can only distribute 1 or more views")

        var lastView: UIView = self
        for view in views {
            view.positionBelowItem(lastView, offset:offset, priority: priority)
            lastView = view
        }
    }

    func positionViewsToTheLeft(views: [UIView], offset: CGFloat = 0, priority: UILayoutPriority? = nil) {
        assert(views.count > 0, "Can only distribute 1 or more views")

        var lastView: UIView = self
        for view in reverse(views) {
            view.positionToTheLeftOfItem(lastView, offset:offset, priority: priority)
            lastView = view
        }
    }

    // MARK: - Between

    func fitBetween(topItem: AnyObject, bottomItem: AnyObject, offset: CGFloat = 0, priority: UILayoutPriority? = nil) -> (top: NSLayoutConstraint, bottom: NSLayoutConstraint){
        return (
            self.positionBelowItem(topItem, offset: offset, priority: priority),
            self.positionAboveItem(bottomItem, offset: offset, priority: priority)
        )
    }

    func fitBetween(leftItem: AnyObject, rightItem: AnyObject, offset: CGFloat = 0, priority: UILayoutPriority? = nil) -> (left: NSLayoutConstraint, right: NSLayoutConstraint){
        return (
            self.positionToTheRightOfItem(leftItem, offset: offset, priority: priority),
            self.positionToTheLeftOfItem(rightItem, offset: offset, priority: priority)
        )
    }

    // MARK: - Fill

    func fillHorizontally(views: [UIView], separation: CGFloat = 0, priority: UILayoutPriority? = nil) {
        assert(views.count > 1, "Can only distribute 2 or more views")

        var lastView: UIView!
        for view in views {
            if lastView != nil{
                lastView.sizeToWidthOfItem(view)
                view.positionToTheRightOfItem(lastView, offset: separation, priority: priority)
            } else {
                view.pinToLeftEdgeOfSuperview(offset: separation, priority: priority)
            }
            lastView = view
        }

        lastView?.pinToRightEdgeOfSuperview(offset: separation, priority: priority)
    }

    func fillVertically(views: [UIView], separation: CGFloat = 0, priority: UILayoutPriority? = nil) {
        assert(views.count > 1, "Can only distribute 2 or more views")

        var lastView: UIView!
        for view in views {
            if lastView != nil{
                lastView.sizeToHeightOfItem(view)
                view.positionBelowItem(lastView, offset: separation, priority: priority)
            } else {
                view.pinToTopEdgeOfSuperview(offset: separation, priority: priority)
            }
            lastView = view
        }

        lastView?.pinToBottomEdgeOfSuperview(offset: separation, priority: priority)
    }

    // MARK: - Bound

    func boundHorizontally(views: [UIView], separation: CGFloat = 0, priority: UILayoutPriority? = nil) {
        assert(views.count > 1, "Can only distribute 2 or more views")

        var lastView: UIView!
        for view in views {
            if lastView != nil{
                view.positionToTheRightOfItem(lastView, offset: separation, priority: priority)
            }
            lastView = view
        }

        self.pinLeftEdgeToLeftEdgeOfItem(views.first!, offset: separation, priority: priority)
        self.pinRightEdgeToRightEdgeOfItem(views.last!, offset: separation, priority: priority)
    }

    func boundVertically(views: [UIView], separation: CGFloat = 0, priority: UILayoutPriority? = nil) {
        assert(views.count > 1, "Can only distribute 2 or more views")

        var lastView: UIView!
        for view in views {
            if lastView != nil{
                view.positionBelowItem(lastView, offset: separation, priority: priority)
            }
            lastView = view
        }

        self.pinTopEdgeToTopEdgeOfItem(views.first!, offset: separation, priority: priority)
        self.pinBottomEdgeToBottomEdgeOfItem(views.last!, offset: separation, priority: priority)
    }

    // MARK: - Private

    private func constrainSizeAttribute(sizeAttribute: NSLayoutAttribute, size: CGFloat = 0, priority: UILayoutPriority? = nil) -> NSLayoutConstraint {
        assert(self.superview != nil, "Can't create constraints without a superview")

        self.setTranslatesAutoresizingMaskIntoConstraints(false)
        let constraint = NSLayoutConstraint(item: self, attribute: sizeAttribute, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 0, constant: size)
        if let p = priority {
            constraint.priority = p
        }
        self.superview!.addConstraint(constraint)
        return constraint
    }

    private func constrainEdgeAttribute(edgeAttribute: NSLayoutAttribute, offset: CGFloat = 0, priority: UILayoutPriority? = nil) -> NSLayoutConstraint{
        assert(self.superview != nil, "Can't create constraints without a superview")

        self.setTranslatesAutoresizingMaskIntoConstraints(false)
        let constraint = NSLayoutConstraint(item: self, attribute: edgeAttribute, relatedBy: .Equal, toItem: self.superview, attribute: edgeAttribute, multiplier: 1, constant: offset)
        if let p = priority {
            constraint.priority = p
        }
        self.superview!.addConstraint(constraint)
        return constraint
    }

    private func constrainAttribute(viewAttribute: NSLayoutAttribute, toAttribute itemAttribute: NSLayoutAttribute, ofItem item: AnyObject, relatedBy: NSLayoutRelation = .Equal, offset: CGFloat = 0, priority: UILayoutPriority? = nil) -> NSLayoutConstraint{
        let commonSuperview: UIView? = {
            if !item.isKindOfClass(UIView) {
                return self.superview?
            }

            return {
                var startView: UIView! = self
                var commonSuperview: UIView?
                do {
                    if item.isDescendantOfView(startView) {
                        commonSuperview = startView
                    }
                    startView = startView.superview
                } while (startView != nil && commonSuperview == nil)

                return commonSuperview
                }()
            }()

        assert(commonSuperview != nil, "Can't create constraints without a common superview")
        
        self.setTranslatesAutoresizingMaskIntoConstraints(false)
        let constraint = NSLayoutConstraint(item: self, attribute: viewAttribute, relatedBy: relatedBy, toItem: item, attribute: itemAttribute, multiplier: 1, constant: offset)
        if let p = priority {
            constraint.priority = p
        }
        commonSuperview!.addConstraint(constraint)
        return constraint
    }
    
}
